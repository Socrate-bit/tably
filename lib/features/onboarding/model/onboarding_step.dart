import 'package:equatable/equatable.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';

/// How a step renders. Each maps to one widget in `widget/steps/`.
enum StepKind {
  welcome,
  text,
  options,
  counter,
  days,
  meals,
  diversity,
  slider,
  info,
  infoBars,
  infoMoney,
  planStart,
  testimonial,
}

/// Card arrangement for an options step.
enum OptionLayout { rows, grid, tiles }

/// One selectable option. [id] is persisted; the label is resolved from l10n.
class OptionSpec extends Equatable {
  const OptionSpec(this.id, {this.icon, this.chip, this.logoAsset});

  final String id;
  final String? icon;

  /// Trailing pill, used for currency codes on the country steps.
  final String? chip;

  /// A store logo drawn instead of a label on the store tiles.
  final String? logoAsset;

  @override
  List<Object?> get props => [id, icon, chip, logoAsset];
}

/// A single onboarding screen, declared once and rendered generically.
class OnboardingStep extends Equatable {
  const OnboardingStep({
    required this.id,
    required this.kind,
    this.progress,
    this.layout = OptionLayout.rows,
    this.options = const [],
    this.multi = false,
    this.maxSelections,
    this.hasNone = false,
    this.requiresOne = false,
    this.serif = false,
    this.continueLabelOverride,
  });

  final String id;
  final StepKind kind;

  /// Progress bar percentage, or null to hide the bar.
  final int? progress;
  final OptionLayout layout;
  final List<OptionSpec> options;
  final bool multi;

  /// Caps a multi-select step (cravings allow three).
  final int? maxSelections;

  /// The step has an exclusive "None" option.
  final bool hasNone;

  /// At least one option must stay selected (appliances).
  final bool requiresOne;

  /// Renders option labels in the serif face (language and country pickers).
  final bool serif;

  /// Overrides the default "continue" label.
  final String? continueLabelOverride;

  bool get showTopBar => kind != StepKind.welcome;

  bool get showContinueButton => kind != StepKind.welcome;

  bool get showProgress => progress != null;

  @override
  List<Object?> get props => [id, kind, progress, layout, options, multi, maxSelections, hasNone, requiresOne, serif, continueLabelOverride];
}

/// Identifiers for steps the cubit needs to reason about by name.
abstract final class StepIds {
  static const welcome = 'welcome';
  static const name = 'name';
  static const age = 'age';
  static const goal = 'goal';
  static const blocker = 'blocker';
  static const infoPlanning = 'info_planning';
  static const infoBars = 'info_bars';
  static const infoMoney = 'info_money';
  static const planStart = 'plan_start';
  static const cookTime = 'cook_time';
  static const country = 'country';
  static const europeCountry = 'europe_country';
  static const store = 'store';
  static const household = 'household';
  static const days = 'days';
  static const mealsPerDay = 'meals_per_day';
  static const diversity = 'diversity';
  static const budget = 'budget';
  static const cravings = 'cravings';
  static const diet = 'diet';
  static const allergies = 'allergies';
  static const proteins = 'proteins';
  static const appliances = 'appliances';
  static const testimonial = 'testimonial';
}

/// The onboarding flow, in order. Progress is spread evenly over the visible steps.
abstract final class OnboardingFlow {
  /// Preference steps reuse the shared enums so ids and icons live in one place.
  static List<OptionSpec> _specs<T extends Enum>(List<T> values, String Function(T) id, String Function(T) icon) =>
      [for (final v in values) OptionSpec(id(v), icon: icon(v))];

  // ignore: unused_element — used by the hidden country steps.
  static List<OptionSpec> _countries(List<Country> countries) =>
      [for (final c in countries) OptionSpec(c.id, icon: c.flag, chip: c.currencyCode)];

  static final steps = <OnboardingStep>[
    const OnboardingStep(id: StepIds.welcome, kind: StepKind.welcome),
    const OnboardingStep(id: StepIds.name, kind: StepKind.text, progress: 5),
    const OnboardingStep(
      id: StepIds.age,
      kind: StepKind.options,
      progress: 10,
      options: [
        OptionSpec('under_24'),
        OptionSpec('25_34'),
        OptionSpec('35_44'),
        OptionSpec('45_54'),
        OptionSpec('55_plus'),
      ],
    ),
    const OnboardingStep(
      id: StepIds.goal,
      kind: StepKind.options,
      progress: 14,
      multi: true,
      options: [
        OptionSpec('meal_prep', icon: '📅'),
        OptionSpec('simple_recipes', icon: '✨'),
        OptionSpec('tasty_recipes', icon: '🤤'),
        OptionSpec('feed_myself', icon: '🍽️'),
        OptionSpec('feed_family', icon: '👨‍👩‍👧'),
      ],
    ),
    const OnboardingStep(
      id: StepIds.blocker,
      kind: StepKind.options,
      progress: 19,
      multi: true,
      options: [
        OptionSpec('no_time', icon: '⏱️'),
        OptionSpec('tired', icon: '😴'),
        OptionSpec('hard', icon: '🤔'),
        OptionSpec('no_inspiration', icon: '💭'),
        OptionSpec('saving', icon: '💰'),
      ],
    ),
    const OnboardingStep(id: StepIds.infoPlanning, kind: StepKind.info, progress: 23),
    const OnboardingStep(id: StepIds.infoBars, kind: StepKind.infoBars, progress: 28),
    const OnboardingStep(id: StepIds.infoMoney, kind: StepKind.infoMoney, progress: 32),
    const OnboardingStep(id: StepIds.planStart, kind: StepKind.planStart, progress: 37),
    const OnboardingStep(
      id: StepIds.cookTime,
      kind: StepKind.options,
      progress: 41,
      options: [
        OptionSpec('15_30'),
        OptionSpec('30_45'),
        OptionSpec('45_60'),
        OptionSpec('60_plus'),
      ],
    ),
    // Region and country steps hidden for now — everyone defaults to France.
    // OnboardingStep(
    //   id: StepIds.country,
    //   kind: StepKind.options,
    //   progress: 43,
    //   serif: true,
    //   options: _countries(const [
    //     Country.unitedStates,
    //     Country.europe,
    //     Country.unitedKingdom,
    //     Country.australia,
    //     Country.canada,
    //     Country.newZealand,
    //     Country.brazil,
    //   ]),
    // ),
    // OnboardingStep(
    //   id: StepIds.europeCountry,
    //   kind: StepKind.options,
    //   progress: 47,
    //   serif: true,
    //   options: _countries(const [
    //     Country.germany,
    //     Country.ireland,
    //     Country.sweden,
    //     Country.netherlands,
    //     Country.france,
    //     Country.spain,
    //     Country.restOfEurope,
    //   ]),
    // ),
    OnboardingStep(
      id: StepIds.store,
      kind: StepKind.options,
      progress: 46,
      layout: OptionLayout.tiles,
      options: [for (final s in Store.values) OptionSpec(s.id, logoAsset: s.logoAsset)],
    ),
    const OnboardingStep(id: StepIds.household, kind: StepKind.counter, progress: 50),
    const OnboardingStep(id: StepIds.days, kind: StepKind.days, progress: 55),
    const OnboardingStep(id: StepIds.mealsPerDay, kind: StepKind.meals, progress: 60),
    const OnboardingStep(id: StepIds.diversity, kind: StepKind.diversity, progress: 64),
    const OnboardingStep(id: StepIds.budget, kind: StepKind.slider, progress: 69),
    OnboardingStep(
      id: StepIds.cravings,
      kind: StepKind.options,
      progress: 73,
      layout: OptionLayout.grid,
      multi: true,
      maxSelections: 3,
      options: _specs(Craving.values, (c) => c.id, (c) => c.icon),
    ),
    OnboardingStep(
      id: StepIds.diet,
      kind: StepKind.options,
      progress: 78,
      layout: OptionLayout.grid,
      multi: true,
      hasNone: true,
      options: _specs(Diet.values, (d) => d.id, (d) => d.icon),
    ),
    OnboardingStep(
      id: StepIds.allergies,
      kind: StepKind.options,
      progress: 82,
      layout: OptionLayout.grid,
      multi: true,
      hasNone: true,
      options: _specs(Allergy.values, (a) => a.id, (a) => a.icon),
    ),
    OnboardingStep(
      id: StepIds.proteins,
      kind: StepKind.options,
      progress: 87,
      layout: OptionLayout.grid,
      multi: true,
      options: _specs(Protein.values, (p) => p.id, (p) => p.icon),
    ),
    OnboardingStep(
      id: StepIds.appliances,
      kind: StepKind.options,
      progress: 91,
      layout: OptionLayout.grid,
      multi: true,
      requiresOne: true,
      continueLabelOverride: 'generate',
      options: _specs(Appliance.values, (a) => a.id, (a) => a.icon),
    ),
    const OnboardingStep(id: StepIds.testimonial, kind: StepKind.testimonial, progress: 96),
  ];
}
