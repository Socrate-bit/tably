import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/model/preference_option.dart';
import '../../../core/model/weekday.dart';
import '../../preferences/model/user_profile.dart';
import '../model/onboarding_step.dart';

part 'onboarding_state.dart';

/// Drives the onboarding flow and assembles the profile as the user answers.
/// Nothing is written to Firestore until [finishGeneration].
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({required AnalyticsService analytics})
      : _analytics = analytics,
        super(const OnboardingState()) {
    unawaited(_analytics.capture(AnalyticsEvents.onboardingStarted));
  }

  final AnalyticsService _analytics;
  final List<Timer> _generationTimers = [];

  /// Budget slider bounds, matching the design.
  static const minBudget = 40.0;
  static const maxBudget = 200.0;

  // ---- Navigation ----

  void next() {
    final current = state.currentStep;
    unawaited(_analytics.capture(
      AnalyticsEvents.onboardingStepCompleted,
      properties: {'step': current.id, 'index': state.stepIndex},
    ));

    if (state.isLastStep) {
      emit(state.copyWith(phase: OnboardingPhase.rating));
      return;
    }
    emit(state.copyWith(stepIndex: state.stepIndex + 1));
  }

  void back() {
    if (state.phase == OnboardingPhase.generating) {
      _cancelGeneration();
      emit(state.copyWith(phase: OnboardingPhase.steps, stepIndex: state.steps.length - 1));
      return;
    }
    if (state.stepIndex == 0) return;
    emit(state.copyWith(stepIndex: state.stepIndex - 1));
  }

  /// Language and store selections advance as soon as the user taps.
  void selectAndAdvance(String optionId) {
    _apply(state.currentStep.id, optionId);
    next();
  }

  // ---- Answers ----

  /// Records an answer for the current step without advancing.
  void select(String optionId) => _apply(state.currentStep.id, optionId);

  void _apply(String stepId, String optionId) {
    final draft = state.draft;
    final next = switch (stepId) {
      StepIds.age => draft.copyWith(ageRange: optionId),
      StepIds.goal => draft.copyWith(goal: optionId),
      StepIds.blocker => draft.copyWith(blocker: optionId),
      StepIds.savings => draft.copyWith(savingsBelief: optionId),
      StepIds.cookTime => draft.copyWith(cookTime: optionId),
      StepIds.source => draft.copyWith(discoverySource: optionId),
      StepIds.country || StepIds.europeCountry => draft.copyWith(country: Country.fromId(optionId)),
      StepIds.store => draft.copyWith(store: optionId),
      StepIds.cravings => draft.copyWith(cravings: _toggleCapped(draft.cravings, Craving.values.byId(optionId), 3)),
      StepIds.diet => draft.copyWith(diets: _toggleWithNone(draft.diets, Diet.values.byId(optionId), Diet.none)),
      StepIds.allergies =>
        draft.copyWith(allergies: _toggleWithNone(draft.allergies, Allergy.values.byId(optionId), Allergy.none)),
      StepIds.proteins => draft.copyWith(proteins: _toggle(draft.proteins, Protein.values.byId(optionId))),
      StepIds.appliances => _withAppliance(draft, Appliance.values.byId(optionId)),
      _ => draft,
    };
    emit(state.copyWith(draft: next));
  }

  /// Returns true when [optionId] is currently selected on the given step.
  bool isSelected(String stepId, String optionId) {
    final d = state.draft;
    return switch (stepId) {
      StepIds.age => d.ageRange == optionId,
      StepIds.goal => d.goal == optionId,
      StepIds.blocker => d.blocker == optionId,
      StepIds.savings => d.savingsBelief == optionId,
      StepIds.cookTime => d.cookTime == optionId,
      StepIds.source => d.discoverySource == optionId,
      StepIds.country || StepIds.europeCountry => d.country.id == optionId,
      StepIds.store => d.store == optionId,
      StepIds.cravings => d.cravings.any((c) => c.id == optionId),
      StepIds.diet => d.diets.any((x) => x.id == optionId),
      StepIds.allergies => d.allergies.any((x) => x.id == optionId),
      StepIds.proteins => d.proteins.any((x) => x.id == optionId),
      StepIds.appliances => d.appliances.any((x) => x.id == optionId),
      _ => false,
    };
  }

  void setName(String name) => emit(state.copyWith(draft: state.draft.copyWith(name: name)));

  void setLanguage(String languageCode) =>
      emit(state.copyWith(draft: state.draft.copyWith(languageCode: languageCode)));

  void incrementHousehold() => _setHousehold(state.draft.household + 1);

  void decrementHousehold() => _setHousehold(state.draft.household - 1);

  void _setHousehold(int value) =>
      emit(state.copyWith(draft: state.draft.copyWith(household: value.clamp(1, 12))));

  void toggleDay(Weekday day) {
    final days = Set<Weekday>.from(state.draft.days);
    days.contains(day) ? days.remove(day) : days.add(day);
    emit(state.copyWith(draft: state.draft.copyWith(days: days)));
  }

  void setBudget(double budget) => emit(
        state.copyWith(draft: state.draft.copyWith(budget: budget.clamp(minBudget, maxBudget))),
      );

  // ---- Rating prompt & generation ----

  /// Dismissing the rating prompt starts the plan build, exactly as in the design.
  void dismissRating() {
    emit(state.copyWith(phase: OnboardingPhase.generating, generationStep: 0));
    _runGeneration();
  }

  /// Steps the checklist on a timer so the build reads as real work.
  void _runGeneration() {
    _cancelGeneration();
    const beats = [
      (Duration(milliseconds: 1500), 1),
      (Duration(milliseconds: 3200), 2),
      (Duration(milliseconds: 4900), 3),
    ];
    for (final (delay, step) in beats) {
      _generationTimers.add(Timer(delay, () {
        if (isClosed || state.phase != OnboardingPhase.generating) return;
        emit(state.copyWith(generationStep: step));
      }));
    }
    _generationTimers.add(Timer(const Duration(milliseconds: 6200), () {
      if (isClosed || state.phase != OnboardingPhase.generating) return;
      finishGeneration();
    }));
  }

  /// Ends onboarding. The listening screen persists [OnboardingState.draft].
  void finishGeneration() {
    _cancelGeneration();
    unawaited(_analytics.capture(
      AnalyticsEvents.onboardingCompleted,
      properties: {
        'household': state.draft.household,
        'days': state.draft.daysCount,
        'budget': state.draft.budget,
        'store': state.draft.store,
      },
    ));
    emit(state.copyWith(phase: OnboardingPhase.done, generationStep: 3));
    debugPrint('[OnboardingCubit] onboarding complete');
  }

  void _cancelGeneration() {
    for (final timer in _generationTimers) {
      timer.cancel();
    }
    _generationTimers.clear();
  }

  // ---- Selection helpers ----

  Set<T> _toggle<T>(Set<T> current, T value) {
    final next = Set<T>.from(current);
    next.contains(value) ? next.remove(value) : next.add(value);
    return next;
  }

  Set<T> _toggleCapped<T>(Set<T> current, T value, int max) {
    if (current.contains(value)) return _toggle(current, value);
    if (current.length >= max) return current;
    return _toggle(current, value);
  }

  Set<T> _toggleWithNone<T>(Set<T> current, T value, T none) {
    if (value == none) return {none};
    final next = Set<T>.from(current)..remove(none);
    next.contains(value) ? next.remove(value) : next.add(value);
    return next.isEmpty ? {none} : next;
  }

  /// At least one appliance must remain selected.
  UserProfile _withAppliance(UserProfile draft, Appliance appliance) {
    final next = _toggle(draft.appliances, appliance);
    return next.isEmpty ? draft : draft.copyWith(appliances: next);
  }

  @override
  Future<void> close() {
    _cancelGeneration();
    return super.close();
  }
}

/// Looks an enum value up by its persisted id.
extension _ById<T extends Enum> on List<T> {
  T byId(String id) => firstWhere(
        (v) => (v as dynamic).id == id,
        orElse: () => first,
      );
}
