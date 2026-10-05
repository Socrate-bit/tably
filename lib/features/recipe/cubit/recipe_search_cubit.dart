import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/model/user_profile.dart';
import '../model/recipe.dart';
import '../service/recipe_ai_service.dart';
import '../service/recipe_search_service.dart';
import 'catalogue_cubit.dart';
import 'recipe_browse_cubit.dart';
import 'search_quota_cubit.dart';

part 'recipe_search_state.dart';

/// Searches Spoonacular for the recipes tab: the search text (translated to
/// English by Gemini) and the browse filters, including the diets, allergies,
/// meats and appliances chosen there in place of the profile's. Gemini then
/// checks and translates the results, as it does the cached pool. Results live in memory; one added to the week joins the pool.
class RecipeSearchCubit extends Cubit<RecipeSearchState> {
  RecipeSearchCubit({
    required RecipeSearchService search,
    required SearchQuotaCubit quota,
    required RecipeAiService ai,
    required ProfileCubit profileCubit,
    required AnalyticsService analytics,
  })  : _search = search,
        _quota = quota,
        _ai = ai,
        _profileCubit = profileCubit,
        _analytics = analytics,
        super(const RecipeSearchState());

  /// Candidates per search, before the price limit and Gemini drop any.
  static const size = 50;

  final RecipeSearchService _search;
  final SearchQuotaCubit _quota;
  final RecipeAiService _ai;
  final ProfileCubit _profileCubit;
  final AnalyticsService _analytics;

  /// Counts searches, so a slow one never overwrites a newer one.
  int _latest = 0;

  /// Searches for [browse], unless its results are already showing. [reload]
  /// always calls the API again: results are random, so it brings new ones.
  /// Nothing to search for clears the results, back to the cached pool.
  Future<void> search(RecipeBrowseState browse, {bool reload = false}) async {
    if (!browse.canSearch) {
      emit(const RecipeSearchState());
      return;
    }
    if (!reload && browse == state.searchedFor && state.status != RecipeSearchStatus.failed) return;

    final run = ++_latest;
    // The filters' diets, allergies and appliances stand in for the profile's.
    final profile = browse.constraints.applyTo(_profileCubit.state.profile);
    final stopwatch = Stopwatch()..start();
    emit(RecipeSearchState(status: RecipeSearchStatus.searching, searchedFor: browse));
    try {
      // Spent searches stop here, before Gemini translates the text.
      _quota.ensureAvailable();
      final text = browse.query.trim();
      final query = text.isEmpty ? null : await _ai.toEnglish(text, profile.languageCode);
      final raw = await _search.search(
        profile,
        number: size,
        query: query,
        cuisines: browse.cuisines,
        // Spoonacular combines filters with AND, so only a single pick narrows
        // the search; several are applied to the results instead.
        craving: browse.searchCraving,
      );
      // Over-budget candidates are dropped before Gemini spends time on them.
      final affordable = [
        for (final r in raw)
          if (browse.fitsPrice((r['price'] as num? ?? 0).toDouble(), profile.store)) r,
      ];
      final recipes = await _adapt(affordable, profile);
      if (isClosed || run != _latest) return;
      emit(RecipeSearchState(status: RecipeSearchStatus.ready, searchedFor: browse, results: recipes));
      debugPrint('[RecipeSearchCubit] "$text" → ${recipes.length} recipes '
          '(${raw.length - affordable.length} over budget) in ${stopwatch.elapsedMilliseconds}ms');
      unawaited(_analytics.capture(AnalyticsEvents.recipeSearched, properties: {
        'has_query': text.isNotEmpty,
        'filters': browse.filterCount,
        'reload': reload,
        'results': recipes.length,
      }));
    } catch (e) {
      debugPrint('[RecipeSearchCubit] search failed: $e');
      if (isClosed || run != _latest) return;
      unawaited(_analytics.capture(AnalyticsEvents.recipeSearchFailed, properties: {'reason': CatalogueCubit.reasonFor(e)}));
      emit(RecipeSearchState(status: RecipeSearchStatus.failed, searchedFor: browse, error: e));
    }
  }

  /// Checks and translates [raw]; nothing surviving is an empty result, not
  /// an error.
  Future<List<Recipe>> _adapt(List<Map<String, dynamic>> raw, UserProfile profile) async {
    if (raw.isEmpty) return const [];
    try {
      return (await _ai.adapt(raw, profile)).recipes;
    } on NoMatchingRecipesException {
      return const [];
    }
  }

  void errorShown() => emit(RecipeSearchState(status: state.status, searchedFor: state.searchedFor, results: state.results));
}
