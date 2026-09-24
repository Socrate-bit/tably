part of 'onboarding_cubit.dart';

/// Where the user is in the pre-app experience.
enum OnboardingPhase { steps, rating, generating, storeSwitch, done }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.phase = OnboardingPhase.steps,
    this.stepIndex = 0,
    this.showLanguage = false,
    this.draft = const UserProfile(),
    this.generationStep = 0,
  });

  final OnboardingPhase phase;
  final int stepIndex;

  /// The language picker, opened from the welcome screen's language pill.
  final bool showLanguage;

  /// The profile being assembled; written to Firestore when onboarding ends.
  final UserProfile draft;

  /// 0–3, driving the generating screen's checklist and progress bar.
  final int generationStep;

  /// The Europe follow-up only appears when the user picked Europe.
  List<OnboardingStep> get steps => OnboardingFlow.steps
      .where((s) => s.id != StepIds.europeCountry || draft.country == Country.europe)
      .toList();

  OnboardingStep get currentStep => steps[stepIndex.clamp(0, steps.length - 1)];

  bool get isLastStep => stepIndex >= steps.length - 1;

  bool get generationComplete => generationStep >= OnboardingCubit.generationTasks;

  /// The week the answers so far would produce, before any regeneration.
  WeekPlan get previewWeek => WeekPlanner.build(profile: draft, settings: const PlanSettings());

  Store get cheaperStore => draft.store.cheapestAlternative;

  bool get hasCheaperStore => cheaperStore.priceFactor < draft.store.priceFactor;

  /// How much cheaper [cheaperStore] is, as a whole percentage.
  int get switchSavingPercent => ((1 - cheaperStore.priceFactor / draft.store.priceFactor) * 100).round();

  OnboardingState copyWith({
    OnboardingPhase? phase,
    int? stepIndex,
    bool? showLanguage,
    UserProfile? draft,
    int? generationStep,
  }) =>
      OnboardingState(
        phase: phase ?? this.phase,
        stepIndex: stepIndex ?? this.stepIndex,
        showLanguage: showLanguage ?? this.showLanguage,
        draft: draft ?? this.draft,
        generationStep: generationStep ?? this.generationStep,
      );

  @override
  List<Object?> get props => [phase, stepIndex, showLanguage, draft, generationStep];
}
