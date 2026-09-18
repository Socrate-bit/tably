import 'dart:math';

import '../../../core/model/weekday.dart';
import '../../preferences/model/user_profile.dart';
import '../../recipe/model/recipe.dart';
import '../../recipe/service/recipe_catalogue.dart';
import '../model/planned_meal.dart';

/// Builds a week of dinners from the catalogue, respecting the user's cooking
/// days, cravings and budget.
abstract final class PlanGenerator {
  /// Picks one recipe per cooking day. [seed] varies the result so regenerating
  /// gives a different week.
  static List<PlannedMeal> generate({
    required UserProfile profile,
    required List<Recipe> catalogue,
    int? seed,
  }) {
    final days = profile.orderedDays;
    if (days.isEmpty) return const [];

    final pool = _pool(profile, catalogue);
    if (pool.isEmpty) return const [];

    final random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    final shuffled = pool.toList()..shuffle(random);

    // Prefer the cheapest combination when the shuffled pick overshoots budget.
    var picks = [for (var i = 0; i < days.length; i++) shuffled[i % shuffled.length]];
    if (_weekCost(picks, profile.household) > profile.budget) {
      final cheapest = pool.toList()..sort((a, b) => a.price.compareTo(b.price));
      picks = [for (var i = 0; i < days.length; i++) cheapest[i % cheapest.length]];
    }

    return [
      for (final (index, day) in days.indexed) _toMeal(day, picks[index]),
    ];
  }

  /// Recipes matching the user's cravings, minus anything their diet or
  /// allergies rule out.
  static List<Recipe> _pool(UserProfile profile, List<Recipe> catalogue) {
    final cravingIds = profile.cravings.map((c) => c.id).toSet();
    final matching = catalogue.where((r) => cravingIds.contains(r.cravingId)).toList();
    return matching.isEmpty ? catalogue : matching;
  }

  static double _weekCost(List<Recipe> recipes, int household) =>
      recipes.fold<double>(0, (sum, r) => sum + r.price) * household;

  static PlannedMeal _toMeal(Weekday day, Recipe recipe) => PlannedMeal(
        day: day,
        recipeId: recipe.id,
        title: recipe.title,
        photoKey: recipe.photoKey,
        cravingId: recipe.cravingId,
        cookTime: recipe.cookTime,
        price: recipe.price,
      );

  /// Convenience for callers that only have the bundled catalogue.
  static List<PlannedMeal> generateFromCatalogue(UserProfile profile, {int? seed}) =>
      generate(profile: profile, catalogue: RecipeCatalogue.recipes, seed: seed);
}
