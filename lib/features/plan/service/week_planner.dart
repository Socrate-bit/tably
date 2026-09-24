import '../../preferences/model/user_profile.dart';
import '../../recipe/model/recipe.dart';
import '../../recipe/service/recipe_catalogue.dart';
import '../model/plan_settings.dart';
import '../model/week_plan.dart';

/// Derives the week from the profile and the user's plan settings. Pure and
/// deterministic, so every device shows the same week for the same inputs.
abstract final class WeekPlanner {
  static WeekPlan build({
    required UserProfile profile,
    required PlanSettings settings,
    List<Recipe> catalogue = RecipeCatalogue.recipes,
  }) {
    final days = profile.orderedDays;
    final mealSlots = MealSlot.forMealsPerDay(profile.mealsPerDay);
    if (days.isEmpty || catalogue.isEmpty) return const WeekPlan();

    // With more than one meal a day each dish is cooked for two services: it
    // comes back as leftovers on the next cooking day, in the same slot.
    final reuse = mealSlots.length == 1 ? 1 : 2;
    final shuffled = _shuffle(catalogue, settings.seed);
    Recipe? byId(String? id) => id == null ? null : catalogue.where((r) => r.id == id).firstOrNull;

    return WeekPlan(slots: [
      for (final (slotIndex, slot) in mealSlots.indexed)
        for (final (dayIndex, day) in days.indexed)
          () {
            final override = byId(settings.overrides[PlanSlot.keyFor(day, slot)]);
            final cookedOn = dayIndex - dayIndex % reuse;
            final isLeftover = override == null && cookedOn != dayIndex;
            // A leftover is whatever was cooked that day, including a swap.
            final cookedOverride =
                isLeftover ? byId(settings.overrides[PlanSlot.keyFor(days[cookedOn], slot)]) : null;
            return PlanSlot(
              day: day,
              slot: slot,
              recipe: override ??
                  cookedOverride ??
                  shuffled[(slotIndex * 4 + dayIndex ~/ reuse) % shuffled.length],
              isLeftover: isLeftover,
              showSlotLabel: mealSlots.length > 1,
            );
          }(),
    ]);
  }

  /// The design's seeded shuffle, reproduced exactly so a given seed yields
  /// the same week the prototype shows.
  static List<Recipe> _shuffle(List<Recipe> pool, int planSeed) {
    final order = List<int>.generate(pool.length, (i) => i);
    var seed = (planSeed + 1) * 9301;
    for (var i = order.length - 1; i > 0; i--) {
      seed = (seed * 9301 + 49297) % 233280;
      final j = (seed / 233280 * (i + 1)).floor();
      final swap = order[i];
      order[i] = order[j];
      order[j] = swap;
    }
    return [for (final i in order) pool[i]];
  }
}
