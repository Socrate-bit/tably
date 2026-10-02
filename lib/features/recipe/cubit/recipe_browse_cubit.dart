import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/util/selection.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../model/dietary_constraints.dart';
import '../model/recipe.dart';

part 'recipe_browse_state.dart';

/// Search text and filters for browsing recipes. Shared by the recipes tab,
/// the filters screen and the replace-meal sheet so they always agree.
/// Diets, allergies and appliances start from the profile and follow it,
/// until the user changes them here for searching.
class RecipeBrowseCubit extends Cubit<RecipeBrowseState> {
  RecipeBrowseCubit({required ProfileCubit profileCubit, required AnalyticsService analytics})
      : _analytics = analytics,
        super(() {
          final constraints = DietaryConstraints.of(profileCubit.state.profile);
          return RecipeBrowseState(constraints: constraints, defaults: constraints);
        }()) {
    _profileSubscription = profileCubit.stream
        .map((s) => DietaryConstraints.of(s.profile))
        .distinct()
        .listen(_followProfile);
  }

  /// Price-per-portion slider bounds, matching the design.
  static const priceFloor = 3.0;
  static const priceCeiling = 12.0;

  final AnalyticsService _analytics;
  late final StreamSubscription<DietaryConstraints> _profileSubscription;

  /// Takes the profile's new constraints as the defaults; the search follows
  /// them too unless the user had changed it.
  void _followProfile(DietaryConstraints profile) {
    final following = state.constraints == state.defaults;
    emit(state.copyWith(defaults: profile, constraints: following ? profile : null));
  }

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

  /// Same rules as the preferences: "none" is exclusive.
  void toggleDiet(Diet diet) => _filter(state.copyWith(
        constraints: state.constraints.copyWith(diets: Selection.toggleWithNone(state.constraints.diets, diet, Diet.none)),
      ));

  void toggleAllergy(Allergy allergy) => _filter(state.copyWith(
        constraints: state.constraints.copyWith(
          allergies: Selection.toggleWithNone(state.constraints.allergies, allergy, Allergy.none),
        ),
      ));

  /// At least one appliance stays selected, as in the preferences.
  void toggleAppliance(Appliance appliance) => _filter(state.copyWith(
        constraints: state.constraints.copyWith(
          appliances: Selection.toggleKeepOne(state.constraints.appliances, appliance),
        ),
      ));

  /// "Réinitialiser": clears every filter and restores the profile's diets,
  /// allergies and appliances, but keeps the search text.
  void resetFilters() => _filter(RecipeBrowseState(
        query: state.query,
        constraints: state.defaults,
        defaults: state.defaults,
      ));

  void _filter(RecipeBrowseState next) {
    emit(next);
    unawaited(_analytics.capture(AnalyticsEvents.recipeFiltersChanged, properties: {'count': next.filterCount}));
  }

  @override
  Future<void> close() {
    _profileSubscription.cancel();
    return super.close();
  }
}
