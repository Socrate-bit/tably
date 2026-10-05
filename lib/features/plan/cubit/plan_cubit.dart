import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../recipe/cubit/catalogue_cubit.dart';
import '../../recipe/cubit/recipe_cubit.dart';
import '../../recipe/model/recipe.dart';
import '../model/plan_settings.dart';
import '../model/week_plan.dart';
import '../service/plan_service.dart';
import '../service/week_planner.dart';

part 'plan_state.dart';

/// Owns the week. Recomputes it whenever the profile (days, meals per day),
/// the recipe catalogue, the saved favourites or the plan settings (seed,
/// swaps) change, so the menu is always current.
class PlanCubit extends Cubit<PlanState> {
  PlanCubit({
    required PlanService service,
    required ProfileCubit profileCubit,
    required CatalogueCubit catalogueCubit,
    required RecipeCubit recipeCubit,
    required AnalyticsService analytics,
  })  : _service = service,
        _profileCubit = profileCubit,
        _catalogueCubit = catalogueCubit,
        _recipeCubit = recipeCubit,
        _analytics = analytics,
        super(const PlanState()) {
    _profileSubscription = profileCubit.stream
        .map((s) => s.profile)
        .distinct()
        .listen((_) => emit(state.copyWith(week: _build(state.settings))));
    _catalogueSubscription = catalogueCubit.stream
        .map((s) => s.recipes)
        .distinct()
        .listen((_) => emit(state.copyWith(week: _build(state.settings))));
    // A swapped-in favourite that left the catalogue resolves from its copy.
    _favouritesSubscription = recipeCubit.stream
        .map((s) => s.savedFavourites)
        .distinct(listEquals)
        .listen((_) => emit(state.copyWith(week: _build(state.settings))));
  }

  final PlanService _service;
  final ProfileCubit _profileCubit;
  final CatalogueCubit _catalogueCubit;
  final RecipeCubit _recipeCubit;
  final AnalyticsService _analytics;
  late final StreamSubscription<Object?> _profileSubscription;
  late final StreamSubscription<Object?> _catalogueSubscription;
  late final StreamSubscription<Object?> _favouritesSubscription;
  StreamSubscription<PlanSettings>? _settingsSubscription;
  String? _uid;

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _settingsSubscription?.cancel();
    emit(state.copyWith(status: PlanStatus.loading, clearError: true));
    _settingsSubscription = _service.watch(uid).listen(
      (settings) => emit(state.copyWith(
        status: PlanStatus.ready,
        settings: settings,
        week: _build(settings),
        clearError: true,
      )),
      onError: (Object e) {
        debugPrint('[PlanCubit] stream error: $e');
        emit(state.copyWith(status: PlanStatus.failed, error: e));
      },
    );
  }

  /// "Régénérer le plan": fetches a fresh pool of recipes (Spoonacular, then
  /// Gemini), then deals a new week from it with every swap dropped. If the
  /// fetch fails the current week stays, and the catalogue reports the error.
  /// Returns whether the week was regenerated.
  Future<bool> regenerate() async {
    if (state.regenerating) return false;
    emit(state.copyWith(regenerating: true, clearError: true));
    final rebuilt = await _catalogueCubit.build(_profileCubit.state.profile);
    if (isClosed) return false;
    if (rebuilt) await _apply(PlanSettings(seed: state.settings.seed + 1));
    emit(state.copyWith(regenerating: false));
    if (rebuilt) {
      unawaited(_analytics.capture(AnalyticsEvents.planRegenerated, properties: {'seed': state.settings.seed}));
    }
    return rebuilt;
  }

  /// Swaps the meal in [slotKey] for [recipe]. One from neither the cached
  /// pool nor the saved favourites — a search result — joins the pool first,
  /// so the week can use it.
  Future<void> replace(String slotKey, Recipe recipe) async {
    final known = _catalogueCubit.state.byId(recipe.id) ?? _recipeCubit.state.savedRecipe(recipe.id);
    if (known == null) unawaited(_catalogueCubit.addRecipe(recipe));
    await _apply(state.settings.copyWith(overrides: {...state.settings.overrides, slotKey: recipe.id}));
    debugPrint('[PlanCubit] meal replaced: $slotKey → ${recipe.id}');
    unawaited(_analytics.capture(
      AnalyticsEvents.mealReplaced,
      properties: {'slot': slotKey, 'recipe_id': recipe.id},
    ));
  }

  /// Swaps the meal in [slot] for a random dish from the cached pool that is
  /// not already in the week, preferring one matching the custom
  /// instructions — no API call — and returns the updated slot so
  /// the caller can show it.
  Future<PlanSlot?> regenerateMeal(PlanSlot slot) async {
    final catalogue = _catalogueCubit.state.recipes.where((r) => r.origin == RecipeOrigin.built).toList();
    final inWeek = state.week.slots.map((s) => s.recipe.id).toSet();
    var pool = catalogue.where((r) => !inWeek.contains(r.id)).toList();
    if (pool.isEmpty) pool = catalogue.where((r) => r.id != slot.recipe.id).toList();
    if (pool.isEmpty) return null;
    if (pool.any((r) => r.wished)) pool = pool.where((r) => r.wished).toList();
    final recipeId = pool[Random().nextInt(pool.length)].id;

    await _apply(state.settings.copyWith(overrides: {...state.settings.overrides, slot.key: recipeId}));
    debugPrint('[PlanCubit] meal regenerated: ${slot.key} → $recipeId');
    unawaited(_analytics.capture(
      AnalyticsEvents.mealRegenerated,
      properties: {'slot': slot.key, 'recipe_id': recipeId},
    ));
    return state.week.slotByKey(slot.key);
  }

  /// Puts [recipeId] in place of [replacedRecipeId] wherever that dish is
  /// cooked this week; its leftovers follow.
  Future<void> replaceRecipe(String replacedRecipeId, String recipeId) async {
    final keys = state.week.slots
        .where((s) => !s.isLeftover && s.recipe.id == replacedRecipeId)
        .map((s) => s.key);
    await _apply(state.settings.copyWith(overrides: {
      ...state.settings.overrides,
      for (final key in keys) key: recipeId,
    }));
    unawaited(_analytics.capture(AnalyticsEvents.mealReplaced, properties: {'recipe_id': recipeId}));
  }

  /// Rearranges the week to show the meals [keys] in that order, as dragged
  /// on the menu. Leftovers follow: each pot is cooked at its first meal.
  Future<void> reorder(List<String> keys) async {
    if (listEquals(keys, [for (final s in state.week.slots) s.key])) return;
    await _apply(state.settings.copyWith(order: keys));
    debugPrint('[PlanCubit] week reordered');
    unawaited(_analytics.capture(AnalyticsEvents.mealMoved));
  }

  /// Shows the change immediately, persists it, and rolls back on failure.
  Future<void> _apply(PlanSettings next) async {
    final previous = state.settings;
    emit(state.copyWith(settings: next, week: _build(next)));
    final uid = _uid;
    if (uid == null) return;
    try {
      await _service.save(uid, next);
    } catch (e) {
      debugPrint('[PlanCubit] save failed: $e');
      emit(state.copyWith(settings: previous, week: _build(previous), regenerating: false, error: e));
    }
  }

  WeekPlan _build(PlanSettings settings) => WeekPlanner.build(
        profile: _profileCubit.state.profile,
        settings: settings,
        catalogue: _catalogueCubit.state.recipes,
        favourites: _recipeCubit.state.savedFavourites,
      );

  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _profileSubscription.cancel();
    _catalogueSubscription.cancel();
    _favouritesSubscription.cancel();
    _settingsSubscription?.cancel();
    return super.close();
  }
}
