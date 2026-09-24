import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../model/plan_settings.dart';
import '../model/week_plan.dart';
import '../service/plan_service.dart';
import '../service/week_planner.dart';

part 'plan_state.dart';

/// Owns the week. Recomputes it whenever the profile (days, meals per day) or
/// the plan settings (seed, swaps) change, so the menu is always current.
class PlanCubit extends Cubit<PlanState> {
  PlanCubit({
    required PlanService service,
    required ProfileCubit profileCubit,
    required AnalyticsService analytics,
  })  : _service = service,
        _profileCubit = profileCubit,
        _analytics = analytics,
        super(const PlanState()) {
    _profileSubscription = profileCubit.stream
        .map((s) => s.profile)
        .distinct()
        .listen((_) => emit(state.copyWith(week: _build(state.settings))));
  }

  /// How long the regenerate icon spins before the new week appears.
  static const regenerateDelay = Duration(milliseconds: 700);

  final PlanService _service;
  final ProfileCubit _profileCubit;
  final AnalyticsService _analytics;
  late final StreamSubscription<Object?> _profileSubscription;
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

  /// Reshuffles the week and drops every swap, after a short spin.
  Future<void> regenerate() async {
    if (state.regenerating) return;
    emit(state.copyWith(regenerating: true, clearError: true));
    await Future<void>.delayed(regenerateDelay);
    if (isClosed) return;
    await _apply(PlanSettings(seed: state.settings.seed + 1));
    emit(state.copyWith(regenerating: false));
    unawaited(_analytics.capture(AnalyticsEvents.planRegenerated, properties: {'seed': state.settings.seed}));
  }

  /// Swaps the meal in [slotKey] for [recipeId].
  Future<void> replace(String slotKey, String recipeId) async {
    await _apply(state.settings.copyWith(overrides: {...state.settings.overrides, slotKey: recipeId}));
    unawaited(_analytics.capture(
      AnalyticsEvents.mealReplaced,
      properties: {'slot': slotKey, 'recipe_id': recipeId},
    ));
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

  WeekPlan _build(PlanSettings settings) =>
      WeekPlanner.build(profile: _profileCubit.state.profile, settings: settings);

  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _profileSubscription.cancel();
    _settingsSubscription?.cancel();
    return super.close();
  }
}
