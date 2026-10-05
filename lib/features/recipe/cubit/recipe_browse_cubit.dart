import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
/// Diets, allergies and appliances start at their widest, except right after
/// onboarding, when they are seeded from the answers just given. After that
/// they are the search's own, and preference changes never touch them.
class RecipeBrowseCubit extends Cubit<RecipeBrowseState> {
  RecipeBrowseCubit({required ProfileCubit profileCubit, required AnalyticsService analytics})
      : _analytics = analytics,
        super(RecipeBrowseState(constraints: RecipeBrowseState.widest)) {
    _profileSubscription = profileCubit.stream.listen(_watchOnboarding);
    _watchOnboarding(profileCubit.state);
  }

  /// Price-per-portion slider bounds, matching the design.
  static const priceFloor = 3.0;
  static const priceCeiling = 12.0;

  final AnalyticsService _analytics;
  late final StreamSubscription<ProfileState> _profileSubscription;

  /// Whether a loaded profile was seen still onboarding.
  bool _onboarding = false;

  /// Seeds the search from the profile's diets, allergies and appliances once
  /// the user finishes onboarding; a profile already onboarded at launch is
  /// ignored.
  void _watchOnboarding(ProfileState profile) {
    if (profile.isLoading) return;
    if (!profile.hasOnboarded) {
      _onboarding = true;
    } else if (_onboarding) {
      _onboarding = false;
      emit(state.copyWith(constraints: DietaryConstraints.of(profile.profile)));
      debugPrint('[RecipeBrowseCubit] filters seeded from onboarding');
    }
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

  /// As in the preferences, ticking nothing means no appliance at all.
  void toggleAppliance(Appliance appliance) => _filter(state.copyWith(
        constraints: state.constraints.copyWith(appliances: Selection.toggle(state.constraints.appliances, appliance)),
      ));

  /// "Réinitialiser": the most permissive search — no chips, no price limit,
  /// no diet or allergy and every appliance — keeping the search text.
  void resetFilters() => _filter(state.cleared);

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
