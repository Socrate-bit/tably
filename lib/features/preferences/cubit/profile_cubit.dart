import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/model/weekday.dart';
import '../../../core/util/selection.dart';
import '../model/user_profile.dart';
import '../service/profile_service.dart';

part 'profile_state.dart';

/// Owns the user's profile. Every edit is applied optimistically to local state
/// and then written to Firestore; the stream reconciles the truth.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required ProfileService service, required AnalyticsService analytics})
      : _service = service,
        _analytics = analytics,
        super(const ProfileState());

  final ProfileService _service;
  final AnalyticsService _analytics;
  StreamSubscription<UserProfile?>? _subscription;
  String? _uid;

  /// Binds to a user's document. Safe to call repeatedly — re-binds only when
  /// the uid actually changed.
  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    _subscription = _service.watch(uid).listen(
      (profile) {
        if (profile == null) {
          emit(state.copyWith(status: ProfileStatus.missing));
          return;
        }
        emit(state.copyWith(status: ProfileStatus.ready, profile: profile, clearError: true));
      },
      onError: (Object e) {
        debugPrint('[ProfileCubit] stream error: $e');
        emit(state.copyWith(status: ProfileStatus.failed, error: e));
      },
    );
  }

  /// Applies a change locally, then persists it.
  Future<void> _update(UserProfile next, {String? changed}) async {
    emit(state.copyWith(status: ProfileStatus.ready, profile: next, clearError: true));
    final uid = _uid;
    if (uid == null) return;
    try {
      await _service.save(uid, next);
      if (changed != null) {
        unawaited(_analytics.capture(
          AnalyticsEvents.preferenceChanged,
          properties: {'field': changed},
        ));
      }
    } catch (e) {
      debugPrint('[ProfileCubit] save failed: $e');
      emit(state.copyWith(error: e));
    }
  }

  /// Persists a profile built during onboarding and marks it complete.
  Future<void> completeOnboarding(UserProfile profile) =>
      _update(profile.copyWith(onboardingComplete: true), changed: 'onboarding');

  /// Sends the user back through onboarding, which is how [RootScreen] decides
  /// what to show. Reserved for admins and creators reviewing the funnel.
  Future<void> replayOnboarding() =>
      _update(state.profile.copyWith(onboardingComplete: false), changed: 'replayOnboarding');

  Future<void> setName(String name) => _update(state.profile.copyWith(name: name), changed: 'name');

  Future<void> setHousehold(int household) => _update(
        state.profile.copyWith(household: household.clamp(UserProfile.minHousehold, UserProfile.maxHousehold)),
        changed: 'household',
      );

  Future<void> incrementHousehold() => setHousehold(state.profile.household + 1);

  Future<void> decrementHousehold() => setHousehold(state.profile.household - 1);

  Future<void> toggleDay(Weekday day) =>
      _update(state.profile.copyWith(days: Selection.toggle(state.profile.days, day)), changed: 'days');

  Future<void> setMealsPerDay(int mealsPerDay) => _update(
        state.profile.copyWith(mealsPerDay: mealsPerDay.clamp(1, UserProfile.maxMealsPerDay)),
        changed: 'mealsPerDay',
      );

  Future<void> setVariety(Variety variety) =>
      _update(state.profile.copyWith(variety: variety), changed: 'variety');

  Future<void> setBudget(double budget) =>
      _update(state.profile.copyWith(budget: budget), changed: 'budget');

  Future<void> setStore(Store store) =>
      _update(state.profile.copyWith(store: store), changed: 'store');

  Future<void> setCountry(Country country) =>
      _update(state.profile.copyWith(country: country), changed: 'country');

  Future<void> setLanguage(String languageCode) =>
      _update(state.profile.copyWith(languageCode: languageCode), changed: 'language');

  Future<void> setWeeklyReminder(bool enabled) =>
      _update(state.profile.copyWith(weeklyReminder: enabled), changed: 'weeklyReminder');

  /// Cravings cap at three, matching the design's "Choisis jusqu'à 3".
  Future<void> toggleCraving(Craving craving) => _update(
        state.profile.copyWith(cravings: Selection.toggleCapped(state.profile.cravings, craving, max: 3)),
        changed: 'cravings',
      );

  Future<void> toggleDiet(Diet diet) => _update(
        state.profile.copyWith(diets: Selection.toggleWithNone(state.profile.diets, diet, Diet.none)),
        changed: 'diets',
      );

  Future<void> toggleAllergy(Allergy allergy) => _update(
        state.profile.copyWith(allergies: Selection.toggleWithNone(state.profile.allergies, allergy, Allergy.none)),
        changed: 'allergies',
      );

  Future<void> toggleProtein(Protein protein) =>
      _update(state.profile.copyWith(proteins: Selection.toggle(state.profile.proteins, protein)), changed: 'proteins');

  /// At least one appliance stays selected — the planner needs somewhere to cook.
  Future<void> toggleAppliance(Appliance appliance) => _update(
        state.profile.copyWith(appliances: Selection.toggleKeepOne(state.profile.appliances, appliance)),
        changed: 'appliances',
      );

  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
