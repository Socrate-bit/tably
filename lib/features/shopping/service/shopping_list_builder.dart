import '../../../core/model/aisle.dart';
import '../../plan/model/week_plan.dart';
import '../../recipe/model/recipe.dart';
import '../model/shopping_item.dart';
import 'shopping_ai_service.dart';

/// Derives the raw shopping lines from the week. Pure, so the same week
/// always gives the same lines; merging similar ones is left to
/// [ShoppingAiService].
abstract final class ShoppingListBuilder {
  /// Every ingredient line the week needs, summed across meals: each slot is
  /// one portion per household member, leftovers included since they are
  /// cooked in the same pot. Only the same ingredient in the same unit sums
  /// here. In order of first appearance.
  static List<Ingredient> linesFromWeek(WeekPlan week, int household) {
    final lines = <(Object, String), Ingredient>{};
    for (final slot in week.slots) {
      for (final i in slot.recipe.ingredients) {
        // Spoonacular gives a few ingredients no id; those sum by name.
        final key = (i.id > 0 ? i.id : i.name, i.unit.id);
        final previous = lines[key];
        lines[key] = Ingredient(
          id: i.id,
          icon: i.icon,
          name: previous?.name ?? i.name,
          amount: (previous?.amount ?? 0) + i.amount * household,
          unit: i.unit,
          aisle: previous?.aisle ?? i.aisle,
        );
      }
    }
    return lines.values.toList();
  }

  /// What a list is built from: the merge rules' version, the language, the
  /// household and how many slots each recipe fills. The list is only
  /// rebuilt when this changes.
  static String sourceOf(WeekPlan week, int household, String languageCode) {
    final counts = <String, int>{};
    for (final slot in week.slots) {
      counts.update(slot.recipe.id, (n) => n + 1, ifAbsent: () => 1);
    }
    final recipes = [for (final e in counts.entries) '${e.key}x${e.value}']..sort();
    return 'v${ShoppingAiService.version}|$languageCode|$household|${recipes.join(',')}';
  }

  /// Groups items into aisle cards, in aisle order.
  static List<ShoppingCategory> groupByAisle(List<ShoppingItem> items) {
    final byAisle = <Aisle, List<ShoppingItem>>{};
    for (final item in items) {
      byAisle.putIfAbsent(item.aisle, () => []).add(item);
    }
    return [
      for (final aisle in Aisle.values)
        if (byAisle[aisle] case final items? when items.isNotEmpty)
          ShoppingCategory(aisle: aisle, items: items..sort((a, b) => a.order.compareTo(b.order))),
    ];
  }
}
