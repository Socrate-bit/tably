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
    final shuffled = _shuffle(catalogue, settings.seed);
    Recipe? byId(String? id) => id == null ? null : catalogue.where((r) => r.id == id).firstOrNull;

    // Meals in eating order, split into [recipesToCook] consecutive runs as
    // even as possible. Each run is one dish: cooked at its first meal, then
    // served as leftovers for the rest. Past the catalogue's size a dish
    // comes back, cooked fresh again.
    final meals = [for (final day in days) for (final slot in mealSlots) (day, slot)];
    final recipes = profile.recipesToCook;
    int runOf(int meal) => meal * recipes ~/ meals.length;
    final firstMealOfRun = <int, int>{};
    for (var i = 0; i < meals.length; i++) {
      firstMealOfRun.putIfAbsent(runOf(i), () => i);
    }

    return WeekPlan(slots: [
      for (final (i, (day, slot)) in meals.indexed)
        () {
          final run = runOf(i);
          final (cookedDay, cookedSlot) = meals[firstMealOfRun[run]!];
          final override = byId(settings.overrides[PlanSlot.keyFor(day, slot)]);
          final isLeftover = override == null && firstMealOfRun[run] != i;
          // A leftover is whatever was cooked for its run, including a swap.
          final cookedOverride = isLeftover ? byId(settings.overrides[PlanSlot.keyFor(cookedDay, cookedSlot)]) : null;
          return PlanSlot(
            day: day,
            slot: slot,
            recipe: override ?? cookedOverride ?? shuffled[run % shuffled.length],
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
