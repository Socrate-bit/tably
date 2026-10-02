import '../../preferences/model/user_profile.dart';
import '../../recipe/model/recipe.dart';
import '../model/plan_settings.dart';
import '../model/week_plan.dart';

/// Derives the week from the profile and the user's plan settings. Pure and
/// deterministic, so every device shows the same week for the same inputs.
abstract final class WeekPlanner {
  static WeekPlan build({
    required UserProfile profile,
    required PlanSettings settings,
    required List<Recipe> catalogue,
    List<Recipe> favourites = const [],
  }) {
    final meals = profile.meals;
    final mealSlots = MealSlot.forMealsPerDay(profile.mealsPerDay);
    if (meals.isEmpty || catalogue.isEmpty) return const WeekPlan();
    final shuffled = _shuffle(catalogue, settings.seed);
    // Swaps may name a saved favourite that has left the catalogue; the
    // shuffle itself only ever draws from the catalogue.
    Recipe? byId(String? id) => id == null
        ? null
        : catalogue.where((r) => r.id == id).firstOrNull ?? favourites.where((r) => r.id == id).firstOrNull;

    // Every fresh window gets a pot; each extra one goes to the window with
    // the most meals per pot, so pots stay as even as possible.
    final windows = profile.freshWindows;
    final potsIn = [for (final _ in windows) 1];
    for (var extra = profile.recipesToCook - windows.length; extra > 0; extra--) {
      var busiest = 0;
      for (var w = 1; w < windows.length; w++) {
        if (windows[w].length * potsIn[busiest] > windows[busiest].length * potsIn[w]) busiest = w;
      }
      potsIn[busiest]++;
    }

    // Within a window the pots take turns (A B A B), so a dish only comes
    // back to back when its window has a single pot. Each pot is cooked at
    // its first meal and served as leftovers for the rest, all within the
    // window, so never past [UserProfile.leftoverHours]. Past the
    // catalogue's size a dish comes back, cooked fresh again.
    final potOf = List.filled(meals.length, 0);
    var firstPot = 0;
    for (final (w, window) in windows.indexed) {
      for (final (j, meal) in window.indexed) {
        potOf[meal] = firstPot + j % potsIn[w];
      }
      firstPot += potsIn[w];
    }
    final cookOf = <int, int>{};
    for (var i = 0; i < meals.length; i++) {
      cookOf.putIfAbsent(potOf[i], () => i);
    }

    // A swapped meal is cooked fresh, never a leftover. Every other meal past
    // its pot's first is served from that first meal's pot.
    bool isLeftover(int i) =>
        byId(settings.overrides[PlanSlot.keyFor(meals[i].$1, meals[i].$2)]) == null && cookOf[potOf[i]] != i;
    final leftoversOf = <int, int>{};
    for (var i = 0; i < meals.length; i++) {
      if (isLeftover(i)) leftoversOf.update(cookOf[potOf[i]]!, (n) => n + 1, ifAbsent: () => 1);
    }

    return WeekPlan(slots: [
      for (final (i, (day, slot)) in meals.indexed)
        () {
          final pot = potOf[i];
          final (cookedDay, cookedSlot) = meals[cookOf[pot]!];
          final override = byId(settings.overrides[PlanSlot.keyFor(day, slot)]);
          final leftover = isLeftover(i);
          // A leftover is whatever was cooked for its pot, including a swap.
          final cookedOverride = leftover ? byId(settings.overrides[PlanSlot.keyFor(cookedDay, cookedSlot)]) : null;
          return PlanSlot(
            day: day,
            slot: slot,
            recipe: override ?? cookedOverride ?? shuffled[pot % shuffled.length],
            isLeftover: leftover,
            // The cook buys for the whole household, for itself and its leftovers.
            portions: leftover ? 0 : profile.household * (1 + (leftoversOf[i] ?? 0)),
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
