import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/model/weekday.dart';
import '../../../core/util/selection.dart';
import '../../plan/model/plan_settings.dart';
import '../../plan/model/week_plan.dart';
import '../../plan/service/week_planner.dart';
import '../../preferences/model/user_profile.dart';
import '../../recipe/cubit/catalogue_cubit.dart';
import '../../recipe/model/recipe.dart';
import '../model/onboarding_step.dart';

part 'onboarding_state.dart';

/// Drives the onboarding flow and assembles the profile as the user answers.
/// Nothing is written to Firestore until the store-switch offer is answered.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({required CatalogueCubit catalogueCubit, required AnalyticsService analytics})
      : _catalogueCubit = catalogueCubit,
        _analytics = analytics,
        super(const OnboardingState()) {
    unawaited(_analytics.capture(AnalyticsEvents.onboardingStarted));
  }

  final CatalogueCubit _catalogueCubit;
  final AnalyticsService _analytics;

  /// Follows the catalogue build to tick the generating checklist.
  StreamSubscription<CatalogueState>? _buildProgress;

  /// Lets the last checklist item land before moving on.
  static const _readyPause = Duration(milliseconds: 700);

  /// Budget slider bounds, matching the design.
  static const minBudget = 40.0;
  static const maxBudget = 200.0;

  /// Items on the generating screen's checklist.
  static const generationTasks = 3;

  // ---- Navigation ----

  void next() {
    if (!state.canContinue) return;
    final current = state.currentStep;
    unawaited(_analytics.capture(
      AnalyticsEvents.onboardingStepCompleted,
      properties: {'step': current.id, 'index': state.stepIndex},
    ));

    if (state.isLastStep) {
      emit(state.copyWith(phase: OnboardingPhase.rating));
      return;
    }
    final nextState = state.copyWith(stepIndex: state.stepIndex + 1);
    // Arriving on the budget step preselects what the planned week would cost.
    emit(nextState.currentStep.id == StepIds.budget
        ? nextState.copyWith(draft: nextState.draft.copyWith(budget: nextState.estimatedBudget))
        : nextState);
  }

  void openLanguage() => emit(state.copyWith(showLanguage: true));

  void closeLanguage() => emit(state.copyWith(showLanguage: false));

  /// Picking a language applies it straight away and returns to the welcome screen.
  void setLanguage(String languageCode) =>
      emit(state.copyWith(showLanguage: false, draft: state.draft.copyWith(languageCode: languageCode)));

  void back() {
    if (state.stepIndex == 0) return;
    emit(state.copyWith(stepIndex: state.stepIndex - 1));
  }

  // ---- Answers ----

  /// Records an answer for the current step without advancing.
  void select(String optionId) => _apply(state.currentStep.id, optionId);

  void _apply(String stepId, String optionId) {
    final draft = state.draft;
    final next = switch (stepId) {
      StepIds.age => draft.copyWith(ageRange: optionId),
      StepIds.goal => draft.copyWith(goals: Selection.toggle(draft.goals, optionId)),
      StepIds.blocker => draft.copyWith(blockers: Selection.toggle(draft.blockers, optionId)),
      StepIds.cookTime => draft.copyWith(cookTime: optionId, cookMinutes: UserProfile.cookMinutesFor(optionId)),
      StepIds.country || StepIds.europeCountry => draft.copyWith(country: Country.fromId(optionId)),
      StepIds.store => draft.copyWith(store: Store.fromId(optionId)),
      StepIds.cravings =>
        draft.copyWith(cravings: Selection.toggleCapped(draft.cravings, Craving.values.byId(optionId), max: 3)),
      StepIds.diet => draft.copyWith(diets: Selection.toggleWithNone(draft.diets, Diet.values.byId(optionId), Diet.none)),
      StepIds.allergies =>
        draft.copyWith(allergies: Selection.toggleWithNone(draft.allergies, Allergy.values.byId(optionId), Allergy.none)),
      StepIds.proteins =>
        draft.copyWith(proteins: Selection.toggleExclusive(draft.proteins, Protein.values.byId(optionId), Protein.noMeat)),
      StepIds.appliances =>
        draft.copyWith(appliances: Selection.toggle(draft.appliances, Appliance.values.byId(optionId))),
      _ => draft,
    };
    emit(state.copyWith(draft: next));
  }

  /// Returns true when [optionId] is currently selected on the given step.
  bool isSelected(String stepId, String optionId) {
    final d = state.draft;
    return switch (stepId) {
      StepIds.age => d.ageRange == optionId,
      StepIds.goal => d.goals.contains(optionId),
      StepIds.blocker => d.blockers.contains(optionId),
      StepIds.cookTime => d.cookTime == optionId,
      StepIds.country || StepIds.europeCountry => d.country.id == optionId,
      StepIds.store => d.store.id == optionId,
      StepIds.cravings => d.cravings.any((c) => c.id == optionId),
      StepIds.diet => d.diets.any((x) => x.id == optionId),
      StepIds.allergies => d.allergies.any((x) => x.id == optionId),
      StepIds.proteins => d.proteins.any((x) => x.id == optionId),
      StepIds.appliances => d.appliances.any((x) => x.id == optionId),
      _ => false,
    };
  }

  void setName(String name) => emit(state.copyWith(draft: state.draft.copyWith(name: name)));

  /// Free-text wishes, saved as the profile's custom instructions. Optional.
  void setCustomInstructions(String text) =>
      emit(state.copyWith(draft: state.draft.copyWith(customInstructions: text.trim())));

  void incrementHousehold() => _setHousehold(state.draft.household + 1);

  void decrementHousehold() => _setHousehold(state.draft.household - 1);

  void _setHousehold(int value) => emit(state.copyWith(
        draft: state.draft.copyWith(household: value.clamp(UserProfile.minHousehold, UserProfile.maxHousehold)),
      ));

  void toggleDay(Weekday day) =>
      emit(state.copyWith(draft: state.draft.copyWith(days: Selection.toggle(state.draft.days, day))));

  void setMealsPerDay(int mealsPerDay) => emit(state.copyWith(draft: state.draft.copyWith(mealsPerDay: mealsPerDay)));

  void setVariety(Variety variety) => emit(state.copyWith(draft: state.draft.copyWith(variety: variety)));

  void setBudget(double budget) => emit(
        state.copyWith(draft: state.draft.copyWith(budget: budget.clamp(minBudget, maxBudget))),
      );

  // ---- Rating prompt & generation ----

  /// Dismissing the rating prompt starts the plan build, exactly as in the design.
  void dismissRating() => _runGeneration();

  /// After a failed build, tries again with the same answers.
  void retryGeneration() => _runGeneration();

  /// Builds the user's real recipe catalogue from their answers, ticking the
  /// checklist as the search, the Gemini check and the save complete.
  Future<void> _runGeneration() async {
    emit(state.copyWith(phase: OnboardingPhase.generating, generationStep: 0, generationFailed: false));
    await _buildProgress?.cancel();
    _buildProgress = _catalogueCubit.stream.listen((catalogue) {
      if (isClosed || !catalogue.isBuilding) return;
      emit(state.copyWith(generationStep: catalogue.step.index));
    });

    final built = await _catalogueCubit.build(state.draft);
    await _buildProgress?.cancel();
    if (isClosed || state.phase != OnboardingPhase.generating) return;
    if (!built) {
      emit(state.copyWith(generationFailed: true));
      return;
    }
    emit(state.copyWith(generationStep: generationTasks, catalogue: _catalogueCubit.state.recipes));
    await Future<void>.delayed(_readyPause);
    if (isClosed || state.phase != OnboardingPhase.generating) return;
    _finishGeneration();
  }

  /// Ends the build, then offers a cheaper store if one exists. Users already
  /// at the cheapest store go straight in, rather than being told a pricier
  /// store would save them money.
  void _finishGeneration() {
    if (!state.hasCheaperStore) {
      _complete(state.draft);
      return;
    }
    emit(state.copyWith(phase: OnboardingPhase.storeSwitch, generationStep: generationTasks));
  }

  /// "Passer à …": switch to the cheapest other store, then finish.
  void acceptStoreSwitch() {
    unawaited(_analytics.capture(AnalyticsEvents.storeSwitchAccepted, properties: {'from': state.draft.store.id}));
    _complete(state.draft.copyWith(store: state.draft.store.cheapestAlternative));
  }

  /// "Garder …": keep the chosen store, then finish.
  void declineStoreSwitch() {
    unawaited(_analytics.capture(AnalyticsEvents.storeSwitchDeclined, properties: {'store': state.draft.store.id}));
    _complete(state.draft);
  }

  /// Ends onboarding. The listening screen persists [OnboardingState.draft].
  void _complete(UserProfile draft) {
    unawaited(_analytics.capture(
      AnalyticsEvents.onboardingCompleted,
      properties: {
        'household': draft.household,
        'days': draft.daysCount,
        'meals_per_day': draft.mealsPerDay,
        'variety': draft.variety.id,
        'budget': draft.budget,
        'store': draft.store.id,
      },
    ));
    emit(state.copyWith(phase: OnboardingPhase.done, draft: draft));
    debugPrint('[OnboardingCubit] onboarding complete');
  }

  @override
  Future<void> close() {
    _buildProgress?.cancel();
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
