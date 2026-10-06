import '../../../core/model/store.dart';
import '../../plan/model/week_plan.dart';
import '../../recipe/model/recipe.dart';
import '../../shopping/model/shopping_item.dart';

/// Compact JSON views of the app for the AI chef: just what it needs to
/// talk and act, so every call stays small.
abstract final class ToolPayloads {
  static double _money(double value) => (value * 100).round() / 100;

  /// Total minutes from "25m".
  static int minutes(Recipe recipe) => int.tryParse(recipe.time.replaceAll(RegExp(r'\D'), '')) ?? 0;

  static Map<String, Object?> recipeSummary(Recipe recipe, Store store) => {
    'id': recipe.id,
    'title': recipe.title,
    'minutes': minutes(recipe),
    'kcal': recipe.macros.kcal,
    'protein_g': recipe.macros.protein,
    'price_eur_per_portion': _money(recipe.price * store.priceFactor),
    'craving': recipe.craving.id,
    'protein': recipe.protein.id,
    if (recipe.cuisine != null) 'cuisine': recipe.cuisine!.id,
    if (recipe.custom) 'custom': true,
  };

  static Map<String, Object?> recipeDetail(Recipe recipe, Store store) => {
    ...recipeSummary(recipe, store),
    'macros': recipe.macros.toMap(),
    'ingredients_per_portion': [
      for (final i in recipe.ingredients) {'name': i.name, 'amount': i.amount, 'unit': i.unit.id},
    ],
    'steps': recipe.steps,
  };

  static Map<String, Object?> week(WeekPlan week, Store store, {required bool recipesOutdated}) => {
    'store': store.id,
    'total_eur': _money(week.totalAt(store)),
    'recipes_outdated': recipesOutdated,
    'meals': [
      for (final s in week.slots)
        {
          'slot_key': s.key,
          'day': s.day.id,
          'meal': s.slot.id,
          'recipe_id': s.recipe.id,
          'title': s.recipe.title,
          if (s.isLeftover) 'leftover': true,
          // So the rules can be checked against what is actually in the dish.
          if (!s.isLeftover) 'ingredients': [for (final i in s.recipe.ingredients) i.name],
        },
    ],
  };

  static List<Map<String, Object?>> shopping(List<ShoppingItem> items) => [
    for (final i in items)
      {
        'id': i.id,
        'name': i.name,
        'amount': i.amount,
        'unit': i.unit.id,
        'aisle': i.aisle.id,
        'checked': i.checked,
        if (i.manual) 'added_by_user': true,
      },
  ];
}
