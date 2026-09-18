import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/model/preference_option.dart';
import '../../../core/model/weekday.dart';
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

  Future<void> setName(String name) => _update(state.profile.copyWith(name: name), changed: 'name');

  Future<void> setHousehold(int household) =>
      _update(state.profile.copyWith(household: household.clamp(1, 12)), changed: 'household');

  Future<void> incrementHousehold() => setHousehold(state.profile.household + 1);

  Future<void> decrementHousehold() => setHousehold(state.profile.household - 1);

  Future<void> toggleDay(Weekday day) {
    final days = Set<Weekday>.from(state.profile.days);
    days.contains(day) ? days.remove(day) : days.add(day);
    return _update(state.profile.copyWith(days: days), changed: 'days');
  }

  Future<void> setBudget(double budget) =>
      _update(state.profile.copyWith(budget: budget), changed: 'budget');

  Future<void> setStore(String store) =>
      _update(state.profile.copyWith(store: store), changed: 'store');

  Future<void> setCountry(Country country) =>
      _update(state.profile.copyWith(country: country), changed: 'country');

  Future<void> setLanguage(String languageCode) =>
      _update(state.profile.copyWith(languageCode: languageCode), changed: 'language');

  Future<void> setWeeklyReminder(bool enabled) =>
      _update(state.profile.copyWith(weeklyReminder: enabled), changed: 'weeklyReminder');

  /// Cravings cap at three, matching the design's "choisis jusqu'à 3".
  Future<void> toggleCraving(Craving craving) {
    final next = _toggleCapped(state.profile.cravings, craving, max: 3);
    return _update(state.profile.copyWith(cravings: next), changed: 'cravings');
  }

  Future<void> toggleDiet(Diet diet) => _update(
        state.profile.copyWith(diets: _toggleWithNone(state.profile.diets, diet, Diet.none)),
        changed: 'diets',
      );

  Future<void> toggleAllergy(Allergy allergy) => _update(
        state.profile.copyWith(
          allergies: _toggleWithNone(state.profile.allergies, allergy, Allergy.none),
        ),
        changed: 'allergies',
      );

  Future<void> toggleProtein(Protein protein) =>
      _update(state.profile.copyWith(proteins: _toggle(state.profile.proteins, protein)), changed: 'proteins');

  /// Appliances must keep at least one selected — the planner needs somewhere to cook.
  Future<void> toggleAppliance(Appliance appliance) {
    final next = _toggle(state.profile.appliances, appliance);
    if (next.isEmpty) return Future.value();
    return _update(state.profile.copyWith(appliances: next), changed: 'appliances');
  }

  Set<T> _toggle<T>(Set<T> current, T value) {
    final next = Set<T>.from(current);
    next.contains(value) ? next.remove(value) : next.add(value);
    return next;
  }

  /// Adds up to [max] entries; selecting beyond the cap is ignored.
  Set<T> _toggleCapped<T>(Set<T> current, T value, {required int max}) {
    if (current.contains(value)) return _toggle(current, value);
    if (current.length >= max) return current;
    return _toggle(current, value);
  }

  /// "None" is exclusive: picking it clears the rest, and clearing everything
  /// falls back to it.
  Set<T> _toggleWithNone<T>(Set<T> current, T value, T none) {
    if (value == none) return {none};
    final next = Set<T>.from(current)..remove(none);
    next.contains(value) ? next.remove(value) : next.add(value);
    return next.isEmpty ? {none} : next;
  }

  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
