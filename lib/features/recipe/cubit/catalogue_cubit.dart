import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/model/user_profile.dart';
import '../model/recipe.dart';
import '../service/recipe_ai_service.dart';
import '../service/recipe_search_service.dart';
import '../service/recipe_service.dart';
import 'search_quota_cubit.dart';

part 'catalogue_state.dart';

/// Owns the user's recipe catalogue. Streams it from Firestore and builds the
/// first one (Spoonacular search, then Gemini check and translation) once
/// onboarding is done. Later preference changes only mark it [outdated]:
/// the user then regenerates the week or keeps it.
class CatalogueCubit extends Cubit<CatalogueState> {
  /// [recipes] seeds the catalogue, for tests that never bind a user.
  CatalogueCubit({
    required RecipeService service,
    required RecipeSearchService search,
    required SearchQuotaCubit quota,
    required RecipeAiService ai,
    required ProfileCubit profileCubit,
    required AnalyticsService analytics,
    List<Recipe> recipes = const [],
  })  : _service = service,
        _search = search,
        _quota = quota,
        _ai = ai,
        _profileCubit = profileCubit,
        _analytics = analytics,
        super(CatalogueState(
          recipes: recipes,
          status: recipes.isEmpty ? CatalogueStatus.loading : CatalogueStatus.ready,
        )) {
    _profileSubscription = profileCubit.stream.map((s) => s.profile).distinct().listen(_check);
  }

  final RecipeService _service;
  final RecipeSearchService _search;
  final SearchQuotaCubit _quota;
  final RecipeAiService _ai;
  final ProfileCubit _profileCubit;
  final AnalyticsService _analytics;
  late final StreamSubscription<UserProfile> _profileSubscription;
  StreamSubscription<List<Recipe>>? _recipesSubscription;
  StreamSubscription<({String? key, String? keptKey})>? _keySubscription;
  String? _uid;
  bool _keyLoaded = false;

  /// The build in flight and the key it is for; a newer key supersedes it.
  Future<bool>? _building;
  String? _buildingKey;

  /// The key whose first build failed, so it isn't retried on every profile
  /// change — only when the user asks.
  String? _failedKey;

  /// Candidates a build asks for. Gemini rejects a good share of them, and
  /// the busiest week cooks 14 recipes, so this leaves spares for
  /// single-meal regenerations. Still one request of the quota.
  static const poolSize = 50;

  /// Identifies the preferences a catalogue depends on. Anything else in the
  /// profile (household, days, store…) only changes the plan, not the recipes.
  static String keyFor(UserProfile profile) {
    String ids(Iterable<String> values) => (values.toList()..sort()).join(',');
    return [
      profile.languageCode,
      ids(profile.diets.map((d) => d.id)),
      ids(profile.allergies.map((a) => a.id)),
      ids(profile.proteins.map((p) => p.id)),
      ids(profile.appliances.map((a) => a.id)),
      // Unchanged since onboarding, the answer stands in, so catalogues
      // stored before the slider existed keep their key.
      profile.cookMinutes == UserProfile.cookMinutesFor(profile.cookTime) ? profile.cookTime ?? '' : '${profile.cookMinutes}',
      // Only when set, for the same reason.
      if (profile.customInstructions.isNotEmpty) profile.customInstructions,
    ].join('|');
  }

  /// Why a build failed, for analytics and the error message.
  static String reasonFor(Object? error) => switch (error) {
        SearchLimitException() || FirebaseFunctionsException(code: 'resource-exhausted') => 'quota',
        FirebaseFunctionsException() => 'search',
        NoMatchingRecipesException() => 'no_match',
        FirebaseAIException() => 'ai',
        _ => 'other',
      };

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _keyLoaded = false;
    _recipesSubscription?.cancel();
    _keySubscription?.cancel();
    _recipesSubscription = _service.watchCatalogue(uid).listen(
      (recipes) {
        emit(state.copyWith(
          recipes: recipes,
          status: state.isBuilding ? CatalogueStatus.building : CatalogueStatus.ready,
        ));
        _check(_profileCubit.state.profile);
      },
      onError: (Object e) {
        debugPrint('[CatalogueCubit] recipes stream error: $e');
        emit(state.copyWith(status: CatalogueStatus.failed, error: e));
      },
    );
    _keySubscription = _service.watchCatalogueKeys(uid).listen(
      (keys) {
        _keyLoaded = true;
        emit(state.copyWith(key: keys.key, keptKey: keys.keptKey, clearKeptKey: keys.keptKey == null));
        _check(_profileCubit.state.profile);
      },
      onError: (Object e) => debugPrint('[CatalogueCubit] key stream error: $e'),
    );
  }

  /// Compares the stored catalogue with [profile]: builds the first one
  /// straight away, and otherwise flags it [CatalogueState.outdated] when
  /// the recipes depend on something that changed and the user has not
  /// already chosen to keep them.
  void _check(UserProfile profile) {
    if (!profile.onboardingComplete || _uid == null || !_keyLoaded || state.status == CatalogueStatus.loading) {
      return;
    }
    final key = keyFor(profile);
    if (state.key == null) {
      if (key != _buildingKey && key != _failedKey) build(profile);
      return;
    }
    final outdated = key != state.key && key != state.keptKey;
    if (outdated != state.outdated) emit(state.copyWith(outdated: outdated));
  }

  /// Keeps the current recipes despite the preferences change, so the user
  /// is not asked again until the preferences change once more.
  Future<void> keep() async {
    final key = keyFor(_profileCubit.state.profile);
    final previous = state;
    emit(state.copyWith(keptKey: key, outdated: false));
    unawaited(_analytics.capture(AnalyticsEvents.catalogueKept));
    final uid = _uid;
    if (uid == null) return;
    try {
      await _service.keepCatalogue(uid, key);
    } catch (e) {
      debugPrint('[CatalogueCubit] keep failed: $e');
      emit(previous.copyWith(error: e));
    }
  }

  /// Retries after a failure, for the current profile.
  Future<bool> retry() => build(_profileCubit.state.profile);

  /// Builds and stores a catalogue for [profile]. Returns true on success.
  /// A second call for the same preferences joins the build in flight.
  Future<bool> build(UserProfile profile) {
    final key = keyFor(profile);
    if (_building case final running? when _buildingKey == key) return running;
    _buildingKey = key;
    final build = _run(profile, key);
    _building = build;
    return build.whenComplete(() {
      if (_buildingKey != key) return;
      _building = null;
      _buildingKey = null;
    });
  }

  /// 1. Searches Spoonacular (one of the user's daily searches), favouring
  ///    what the custom instructions ask for
  /// 2. Has Gemini drop what breaks a constraint and translate the rest
  /// 3. Replaces the stored catalogue, which the plan then reads
  Future<bool> _run(UserProfile profile, String key) async {
    bool superseded() => isClosed || _buildingKey != key;
    final stopwatch = Stopwatch()..start();
    emit(state.copyWith(status: CatalogueStatus.building, step: CatalogueStep.searching, clearError: true));
    try {
      _quota.ensureAvailable();
      final raw = await _search.search(profile, number: poolSize, wish: await _wish(profile));
      if (superseded()) return false;
      emit(state.copyWith(step: CatalogueStep.adapting));

      final adapted = await _ai.adapt(raw, profile);
      if (superseded()) return false;
      emit(state.copyWith(step: CatalogueStep.saving));

      final recipes = [...adapted.recipes]..sort((a, b) => a.id.compareTo(b.id));
      final uid = _uid;
      if (uid != null) await _service.replaceCatalogue(uid, recipes, key);
      if (isClosed) return false;

      _failedKey = null;
      emit(state.copyWith(
        status: CatalogueStatus.ready,
        // The user's custom recipes survive a rebuild.
        recipes: [...recipes, ...state.recipes.where((r) => r.custom)]..sort((a, b) => a.id.compareTo(b.id)),
        key: key,
        clearKeptKey: true,
        outdated: false,
      ));
      debugPrint('[CatalogueCubit] built ${recipes.length} recipes in ${stopwatch.elapsedMilliseconds}ms');
      unawaited(_analytics.capture(AnalyticsEvents.catalogueBuilt, properties: {
        'candidates': raw.length,
        'kept': recipes.length,
        'rejected': adapted.rejected,
        'ms': stopwatch.elapsedMilliseconds,
      }));
      return true;
    } catch (e) {
      debugPrint('[CatalogueCubit] build failed: $e');
      if (superseded()) return false;
      _failedKey = key;
      unawaited(_analytics.capture(AnalyticsEvents.catalogueBuildFailed, properties: {'reason': reasonFor(e)}));
      emit(state.copyWith(
        status: state.recipes.isEmpty ? CatalogueStatus.failed : CatalogueStatus.ready,
        error: e,
      ));
      return false;
    }
  }

  /// The English search for what the custom instructions ask for, or null.
  /// A failure only loses the preference, never the build.
  Future<String?> _wish(UserProfile profile) async {
    if (profile.customInstructions.isEmpty) return null;
    try {
      return await _ai.wishQuery(profile.customInstructions);
    } catch (e) {
      debugPrint('[CatalogueCubit] wish query failed: $e');
      return null;
    }
  }

  /// Adds a recipe found by search or written by the AI chef to the pool,
  /// so the week can use it. Both already respect this user's constraints.
  Future<void> addRecipe(Recipe recipe) async {
    if (state.byId(recipe.id) != null) return;
    if (recipe.origin == RecipeOrigin.built) recipe = recipe.withOrigin(RecipeOrigin.added);
    final previous = state.recipes;
    emit(state.copyWith(recipes: [...previous, recipe]..sort((a, b) => a.id.compareTo(b.id))));
    final uid = _uid;
    if (uid == null) return;
    try {
      await _service.saveRecipe(uid, recipe);
    } catch (e) {
      debugPrint('[CatalogueCubit] addRecipe failed: $e');
      emit(state.copyWith(recipes: previous, error: e));
    }
  }

  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _profileSubscription.cancel();
    _recipesSubscription?.cancel();
    _keySubscription?.cancel();
    return super.close();
  }
}
