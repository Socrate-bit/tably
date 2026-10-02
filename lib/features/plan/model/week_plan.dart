import 'package:equatable/equatable.dart';

import '../../../core/model/store.dart';
import '../../../core/model/weekday.dart';
import '../../recipe/model/recipe.dart';

/// A meal of the day. Order matters: it is the order slots are listed in a day.
enum MealSlot {
  lunch('lunch'),
  dinner('dinner');

  const MealSlot(this.id);
  final String id;

  /// The slots planned for [mealsPerDay]: dinner only, then lunch + dinner.
  static List<MealSlot> forMealsPerDay(int mealsPerDay) => mealsPerDay == 1 ? const [dinner] : const [lunch, dinner];
}

/// One meal in the week.
class PlanSlot extends Equatable {
  const PlanSlot({
    required this.day,
    required this.slot,
    required this.recipe,
    required this.isLeftover,
    required this.portions,
    required this.showSlotLabel,
  });

  final Weekday day;
  final MealSlot slot;
  final Recipe recipe;

  /// Served from an earlier meal's pot and reheated — free and quick.
  final bool isLeftover;

  /// Portions cooked at this meal for the whole household: its own plus every
  /// leftover it feeds. 0 for a leftover, which was paid for when cooked.
  final int portions;

  /// Slot names only show when there is more than one meal a day.
  final bool showSlotLabel;

  /// Identifies the slot across regenerations, e.g. `monday|dinner`.
  String get key => keyFor(day, slot);

  static String keyFor(Weekday day, MealSlot slot) => '${day.id}|${slot.id}';

  @override
  List<Object?> get props => [day, slot, recipe, isLeftover, portions, showSlotLabel];
}

/// The computed week: every slot plus the figures the menu shows.
class WeekPlan extends Equatable {
  const WeekPlan({this.slots = const []});

  final List<PlanSlot> slots;

  /// Slots that need cooking; leftovers cost nothing extra.
  Iterable<PlanSlot> get _cooked => slots.where((s) => !s.isLeftover);

  /// Distinct recipes to cook this week.
  int get recipeCount => _cooked.map((s) => s.recipe.id).toSet().length;

  int get slotCount => slots.length;

  /// Cost of every portion cooked — the same as every meal for the whole
  /// household, leftovers included — at the recipes' reference prices, before
  /// the store factor.
  double get baseTotal => slots.fold(0, (sum, s) => sum + s.recipe.price * s.portions);

  double totalAt(Store store) => baseTotal * store.priceFactor;

  /// Slots grouped by day, in calendar order, each day's slots in meal order.
  List<(Weekday, List<PlanSlot>)> get byDay => [
        for (final day in Weekday.values)
          if (slots.where((s) => s.day == day).toList() case final daySlots when daySlots.isNotEmpty)
            (day, daySlots..sort((a, b) => a.slot.index.compareTo(b.slot.index))),
      ];

  PlanSlot? slotByKey(String key) => slots.where((s) => s.key == key).firstOrNull;

  @override
  List<Object?> get props => [slots];
}
