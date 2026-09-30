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
    this.generationFailed = false,
    this.catalogue = const [],
  });

  final OnboardingPhase phase;
  final int stepIndex;

  /// The language picker, opened from the welcome screen's language pill.
  final bool showLanguage;

  /// The profile being assembled; written to Firestore when onboarding ends.
  final UserProfile draft;

  /// 0–3, driving the generating screen's checklist and progress bar.
  final int generationStep;

  /// The recipe build failed; the generating screen offers a retry.
  final bool generationFailed;

  /// The recipes built for [draft], empty until generation succeeds.
  final List<Recipe> catalogue;

  /// The Europe follow-up only appears when the user picked Europe.
  List<OnboardingStep> get steps => OnboardingFlow.steps
      .where((s) => s.id != StepIds.europeCountry || draft.country == Country.europe)
      .toList();

  OnboardingStep get currentStep => steps[stepIndex.clamp(0, steps.length - 1)];

  /// Steps that ask for an answer stay locked until one is given.
  bool get canContinue => switch (currentStep.id) {
        StepIds.name => draft.name.trim().isNotEmpty,
        StepIds.age => draft.ageRange != null,
        StepIds.goal => draft.goals.isNotEmpty,
        StepIds.blocker => draft.blockers.isNotEmpty,
        StepIds.cookTime => draft.cookTime != null,
        StepIds.days => draft.days.isNotEmpty,
        StepIds.cravings => draft.cravings.isNotEmpty,
        StepIds.diet => draft.diets.isNotEmpty,
        StepIds.allergies => draft.allergies.isNotEmpty,
        StepIds.proteins => draft.proteins.isNotEmpty,
        StepIds.appliances => draft.appliances.isNotEmpty,
        _ => true,
      };

  bool get isLastStep => stepIndex >= steps.length - 1;

  bool get generationComplete => generationStep >= OnboardingCubit.generationTasks;

  /// The week the answers so far would produce, before any regeneration.
  WeekPlan get previewWeek => WeekPlanner.build(profile: draft, settings: const PlanSettings(), catalogue: catalogue);

  /// Weekly groceries beyond the planned meals: breakfasts, snacks, pantry.
  static const _everydayGroceries = 1.3;

  /// A typical portion price (EUR), for estimates made before any recipe exists.
  static const referencePortionPrice = 3.0;

  /// A realistic weekly budget: every planned portion, leftovers included since
  /// they are cooked in the same pot, for the whole household at the chosen
  /// store, plus everyday groceries. Rounded to 5 and kept within the slider.
  /// Before the recipes are built, each meal counts [referencePortionPrice].
  double get estimatedBudget {
    final week = previewWeek;
    final portions = catalogue.isEmpty
        ? draft.mealCount * referencePortionPrice
        : week.slots.fold<double>(0, (sum, s) => sum + s.recipe.price);
    final perPortion = portions * draft.store.priceFactor;
    final cost = perPortion * draft.household * _everydayGroceries;
    return ((cost / 5).round() * 5.0).clamp(OnboardingCubit.minBudget, OnboardingCubit.maxBudget);
  }

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
    bool? generationFailed,
    List<Recipe>? catalogue,
  }) =>
      OnboardingState(
        phase: phase ?? this.phase,
        stepIndex: stepIndex ?? this.stepIndex,
        showLanguage: showLanguage ?? this.showLanguage,
        draft: draft ?? this.draft,
        generationStep: generationStep ?? this.generationStep,
        generationFailed: generationFailed ?? this.generationFailed,
        catalogue: catalogue ?? this.catalogue,
      );

  @override
  List<Object?> get props => [phase, stepIndex, showLanguage, draft, generationStep, generationFailed, catalogue];
}
