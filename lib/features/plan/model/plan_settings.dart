import 'package:equatable/equatable.dart';

/// What the user has changed about their week, stored at
/// `users/{uid}/plan/week`. The week itself is derived from this plus the
/// profile, so changing cooking days or meals per day reflows it instantly.
class PlanSettings extends Equatable {
  const PlanSettings({this.seed = 0, this.overrides = const {}, this.order = const []});

  /// Bumped by "régénérer le plan" to reshuffle the week.
  final int seed;

  /// Meals the user swapped in, keyed by [PlanSlot.key] to a recipe id.
  final Map<String, String> overrides;

  /// Meals the user dragged into a new order: every [PlanSlot.key] in the
  /// order the week shows them. Empty, or stale after the days change, keeps
  /// the planned order.
  final List<String> order;

  PlanSettings copyWith({int? seed, Map<String, String>? overrides, List<String>? order}) =>
      PlanSettings(seed: seed ?? this.seed, overrides: overrides ?? this.overrides, order: order ?? this.order);

  Map<String, dynamic> toMap() => {'seed': seed, 'overrides': overrides, 'order': order};

  factory PlanSettings.fromMap(Map<String, dynamic> map) => PlanSettings(
        seed: (map['seed'] as num?)?.toInt() ?? 0,
        overrides: Map<String, String>.from(
          (map['overrides'] as Map? ?? const {}).map((k, v) => MapEntry('$k', '$v')),
        ),
        order: [for (final key in map['order'] as List? ?? const []) '$key'],
      );

  @override
  List<Object?> get props => [seed, overrides, order];
}
