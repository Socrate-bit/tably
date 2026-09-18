import 'package:equatable/equatable.dart';

import '../../../core/model/preference_option.dart';

/// How a step renders. Each maps to one widget in `widget/steps/`.
enum StepKind {
  language,
  welcome,
  text,
  options,
  counter,
  days,
  slider,
  info,
  infoBars,
  infoMoney,
  testimonial,
}

/// Card arrangement for an options step.
enum OptionLayout { rows, grid, tiles }

/// One selectable option. [id] is persisted; the label is resolved from l10n.
class OptionSpec extends Equatable {
  const OptionSpec(this.id, {this.icon, this.chip});

  final String id;
  final String? icon;

  /// Trailing pill, used for currency codes on the country steps.
  final String? chip;

  @override
  List<Object?> get props => [id, icon, chip];
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

  bool get showTopBar => kind != StepKind.language && kind != StepKind.welcome;

  bool get showContinueButton => kind != StepKind.language && kind != StepKind.welcome;

  bool get showProgress => progress != null;

  @override
  List<Object?> get props => [id, kind, progress, layout, options, multi, maxSelections, hasNone, requiresOne, serif, continueLabelOverride];
}

/// Identifiers for steps the cubit needs to reason about by name.
abstract final class StepIds {
  static const language = 'language';
  static const welcome = 'welcome';
  static const name = 'name';
  static const age = 'age';
  static const goal = 'goal';
  static const blocker = 'blocker';
  static const infoPlanning = 'info_planning';
  static const savings = 'savings';
  static const cookTime = 'cook_time';
  static const source = 'source';
  static const infoBars = 'info_bars';
  static const country = 'country';
  static const europeCountry = 'europe_country';
  static const store = 'store';
  static const household = 'household';
  static const days = 'days';
  static const budget = 'budget';
  static const infoMoney = 'info_money';
  static const cravings = 'cravings';
  static const diet = 'diet';
  static const allergies = 'allergies';
  static const proteins = 'proteins';
  static const appliances = 'appliances';
  static const testimonial = 'testimonial';
}

/// The onboarding flow, in order and with the exact progress values from the design.
abstract final class OnboardingFlow {
  /// Preference steps reuse the shared enums so ids and icons live in one place.
  static List<OptionSpec> _specs<T extends Enum>(List<T> values, String Function(T) id, String Function(T) icon) =>
      [for (final v in values) OptionSpec(id(v), icon: icon(v))];

  static final steps = <OnboardingStep>[
    const OnboardingStep(id: StepIds.language, kind: StepKind.language),
    const OnboardingStep(id: StepIds.welcome, kind: StepKind.welcome),
    const OnboardingStep(id: StepIds.name, kind: StepKind.text, progress: 5),
    const OnboardingStep(
      id: StepIds.age,
      kind: StepKind.options,
      progress: 9,
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
      progress: 13,
      options: [
        OptionSpec('meal_prep', icon: '\u{1F4C5}'),
        OptionSpec('simple_recipes', icon: '\u{2728}'),
        OptionSpec('tasty_recipes', icon: '\u{1F924}'),
        OptionSpec('feed_myself', icon: '\u{1F37D}\u{FE0F}'),
        OptionSpec('feed_family', icon: '\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}'),
      ],
    ),
    const OnboardingStep(
      id: StepIds.blocker,
      kind: StepKind.options,
      progress: 17,
      options: [
        OptionSpec('no_time', icon: '\u{23F1}\u{FE0F}'),
        OptionSpec('tired', icon: '\u{1F634}'),
        OptionSpec('hard', icon: '\u{1F914}'),
        OptionSpec('no_inspiration', icon: '\u{1F4AD}'),
      ],
    ),
    const OnboardingStep(id: StepIds.infoPlanning, kind: StepKind.info, progress: 21),
    const OnboardingStep(
      id: StepIds.savings,
      kind: StepKind.options,
      progress: 26,
      options: [
        OptionSpec('definitely'),
        OptionSpec('very_likely'),
        OptionSpec('a_bit'),
        OptionSpec('not_really'),
      ],
    ),
    const OnboardingStep(
      id: StepIds.cookTime,
      kind: StepKind.options,
      progress: 30,
      options: [
        OptionSpec('15_30'),
        OptionSpec('30_45'),
        OptionSpec('45_60'),
        OptionSpec('60_plus'),
      ],
    ),
    const OnboardingStep(
      id: StepIds.source,
      kind: StepKind.options,
      progress: 34,
      options: [
        OptionSpec('instagram', icon: '\u{1F4F7}'),
        OptionSpec('tiktok', icon: '\u{1F3B5}'),
        OptionSpec('youtube', icon: '\u{25B6}\u{FE0F}'),
        OptionSpec('facebook', icon: '\u{1F175}'),
        OptionSpec('word_of_mouth', icon: '\u{1F4AC}'),
        OptionSpec('app_store', icon: '\u{1F170}'),
      ],
    ),
    const OnboardingStep(id: StepIds.infoBars, kind: StepKind.infoBars, progress: 38),
    OnboardingStep(
      id: StepIds.country,
      kind: StepKind.options,
      progress: 43,
      serif: true,
      options: [
        for (final c in const [
          Country.unitedStates,
          Country.europe,
          Country.unitedKingdom,
          Country.australia,
          Country.canada,
          Country.newZealand,
          Country.brazil,
        ])
          OptionSpec(c.id, icon: c.flag, chip: c.currencyCode),
      ],
    ),
    OnboardingStep(
      id: StepIds.europeCountry,
      kind: StepKind.options,
      progress: 47,
      serif: true,
      options: [
        for (final c in const [
          Country.germany,
          Country.ireland,
          Country.sweden,
          Country.netherlands,
          Country.france,
          Country.spain,
          Country.restOfEurope,
        ])
          OptionSpec(c.id, icon: c.flag, chip: c.currencyCode),
      ],
    ),
    OnboardingStep(
      id: StepIds.store,
      kind: StepKind.options,
      progress: 51,
      layout: OptionLayout.tiles,
      options: [for (final s in Stores.all) OptionSpec(s)],
    ),
    const OnboardingStep(id: StepIds.household, kind: StepKind.counter, progress: 56),
    const OnboardingStep(id: StepIds.days, kind: StepKind.days, progress: 60),
    const OnboardingStep(id: StepIds.budget, kind: StepKind.slider, progress: 64),
    const OnboardingStep(id: StepIds.infoMoney, kind: StepKind.infoMoney, progress: 68),
    OnboardingStep(
      id: StepIds.cravings,
      kind: StepKind.options,
      progress: 74,
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
      progress: 83,
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
