part of 'onboarding_cubit.dart';

/// Where the user is in the pre-app experience.
enum OnboardingPhase { steps, rating, generating, done }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.phase = OnboardingPhase.steps,
    this.stepIndex = 0,
    this.draft = const UserProfile(),
    this.generationStep = 0,
  });

  final OnboardingPhase phase;
  final int stepIndex;

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

  bool get generationComplete => generationStep >= 3;

  OnboardingState copyWith({
    OnboardingPhase? phase,
    int? stepIndex,
    UserProfile? draft,
    int? generationStep,
  }) =>
      OnboardingState(
        phase: phase ?? this.phase,
        stepIndex: stepIndex ?? this.stepIndex,
        draft: draft ?? this.draft,
        generationStep: generationStep ?? this.generationStep,
      );

  @override
  List<Object?> get props => [phase, stepIndex, draft, generationStep];
}
