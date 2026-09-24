import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/util/selection.dart';
import '../model/recipe.dart';

part 'recipe_browse_state.dart';

/// Search text and filters for browsing recipes. Shared by the recipes tab,
/// the filters screen and the replace-meal sheet so they always agree.
class RecipeBrowseCubit extends Cubit<RecipeBrowseState> {
  RecipeBrowseCubit({required AnalyticsService analytics})
      : _analytics = analytics,
        super(const RecipeBrowseState());

  /// Price-per-portion slider bounds, matching the design.
  static const priceFloor = 3.0;
  static const priceCeiling = 12.0;

  final AnalyticsService _analytics;

  void search(String query) => emit(state.copyWith(query: query));

  void clearSearch() => emit(state.copyWith(query: ''));

  void toggleCraving(Craving craving) =>
      _filter(state.copyWith(cravings: Selection.toggle(state.cravings, craving)));

  void toggleCuisine(Cuisine cuisine) =>
      _filter(state.copyWith(cuisines: Selection.toggle(state.cuisines, cuisine)));

  void toggleProtein(RecipeProtein protein) =>
      _filter(state.copyWith(proteins: Selection.toggle(state.proteins, protein)));

  void setMaxPrice(double price) =>
      _filter(state.copyWith(maxPrice: price.clamp(priceFloor, priceCeiling)));

  /// "Réinitialiser": clears every filter but keeps the search text.
  void resetFilters() => _filter(RecipeBrowseState(query: state.query));

  void _filter(RecipeBrowseState next) {
    emit(next);
    unawaited(_analytics.capture(AnalyticsEvents.recipeFiltersChanged, properties: {'count': next.filterCount}));
  }
}
