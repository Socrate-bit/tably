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

part 'catalogue_state.dart';

/// Owns the user's recipe catalogue. Streams it from Firestore and rebuilds
/// it (Spoonacular search, then Gemini check and translation) whenever the
/// preferences it was built for change.
class CatalogueCubit extends Cubit<CatalogueState> {
  /// [recipes] seeds the catalogue, for tests that never bind a user.
  CatalogueCubit({
    required RecipeService service,
    required RecipeSearchService search,
    required RecipeAiService ai,
    required ProfileCubit profileCubit,
    required AnalyticsService analytics,
    List<Recipe> recipes = const [],
  })  : _service = service,
        _search = search,
        _ai = ai,
        _profileCubit = profileCubit,
        _analytics = analytics,
        super(CatalogueState(
          recipes: recipes,
          status: recipes.isEmpty ? CatalogueStatus.loading : CatalogueStatus.ready,
        )) {
    _profileSubscription = profileCubit.stream.map((s) => s.profile).distinct().listen(_scheduleRebuild);
  }

  /// Preferences save on every tap; wait for the user to settle before
  /// spending a search on the new answers.
  static const rebuildDelay = Duration(seconds: 3);

  final RecipeService _service;
  final RecipeSearchService _search;
  final RecipeAiService _ai;
  final ProfileCubit _profileCubit;
  final AnalyticsService _analytics;
  late final StreamSubscription<UserProfile> _profileSubscription;
  StreamSubscription<List<Recipe>>? _recipesSubscription;
  StreamSubscription<String?>? _keySubscription;
  Timer? _rebuildTimer;
  String? _uid;
  bool _keyLoaded = false;

  /// The build in flight and the key it is for; a newer key supersedes it.
  Future<bool>? _building;
  String? _buildingKey;

  /// The key whose last build failed, so it isn't retried on every profile
  /// change — only when the user asks.
  String? _failedKey;

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
      profile.cookTime ?? '',
    ].join('|');
  }

  /// Why a build failed, for analytics and the error message.
  static String reasonFor(Object? error) => switch (error) {
        FirebaseFunctionsException(code: 'resource-exhausted') => 'quota',
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
        _scheduleRebuild(_profileCubit.state.profile);
      },
      onError: (Object e) {
        debugPrint('[CatalogueCubit] recipes stream error: $e');
        emit(state.copyWith(status: CatalogueStatus.failed, error: e));
      },
    );
    _keySubscription = _service.watchCatalogueKey(uid).listen(
      (key) {
        _keyLoaded = true;
        emit(state.copyWith(key: key));
        _scheduleRebuild(_profileCubit.state.profile);
      },
      onError: (Object e) => debugPrint('[CatalogueCubit] key stream error: $e'),
    );
  }

  /// Rebuilds once the stored catalogue no longer matches [profile]:
  /// straight away when there is none yet, after [rebuildDelay] otherwise.
  void _scheduleRebuild(UserProfile profile) {
    if (!profile.onboardingComplete || _uid == null || !_keyLoaded || state.status == CatalogueStatus.loading) {
      return;
    }
    final key = keyFor(profile);
    _rebuildTimer?.cancel();
    if (key == state.key || key == _buildingKey || key == _failedKey) return;
    _rebuildTimer = Timer(
      state.key == null ? Duration.zero : rebuildDelay,
      () => build(_profileCubit.state.profile),
    );
  }

  /// Retries after a failure, for the current profile.
  Future<bool> retry() => build(_profileCubit.state.profile);

  /// Builds and stores a catalogue for [profile]. Returns true on success.
  /// A second call for the same preferences joins the build in flight.
  Future<bool> build(UserProfile profile) {
    final key = keyFor(profile);
    if (_building case final running? when _buildingKey == key) return running;
    _rebuildTimer?.cancel();
    _buildingKey = key;
    final build = _run(profile, key);
    _building = build;
    return build.whenComplete(() {
      if (_buildingKey != key) return;
      _building = null;
      _buildingKey = null;
    });
  }

  /// 1. Searches Spoonacular (one request of the daily quota)
  /// 2. Has Gemini drop what breaks a constraint and translate the rest
  /// 3. Replaces the stored catalogue, which the plan then reads
  Future<bool> _run(UserProfile profile, String key) async {
    bool superseded() => isClosed || _buildingKey != key;
    final stopwatch = Stopwatch()..start();
    emit(state.copyWith(status: CatalogueStatus.building, step: CatalogueStep.searching, clearError: true));
    try {
      final raw = await _search.search(profile);
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
      emit(state.copyWith(status: CatalogueStatus.ready, recipes: recipes, key: key));
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

  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _profileSubscription.cancel();
    _recipesSubscription?.cancel();
    _keySubscription?.cancel();
    _rebuildTimer?.cancel();
    return super.close();
  }
}
