import '../../../core/model/aisle.dart';
import '../../../core/model/ingredient_unit.dart';
import '../../plan/model/week_plan.dart';
import '../../recipe/model/recipe.dart';
import '../model/shopping_item.dart';

/// Derives the shopping list from the week. Pure, so the same week always
/// gives the same list.
abstract final class ShoppingListBuilder {
  /// Every ingredient the week needs, summed across meals: each slot is one
  /// portion per household member, leftovers included since they are cooked
  /// in the same pot. The same ingredient merges into one line whatever its
  /// units. Sorted by aisle, then name.
  static List<ShoppingItem> fromWeek(WeekPlan week, int household) {
    final lines = <String, ({Ingredient first, Map<IngredientUnit, double> amounts})>{};
    for (final slot in week.slots) {
      for (final ingredient in slot.recipe.ingredients) {
        final line = lines.putIfAbsent(_key(ingredient), () => (first: ingredient, amounts: {}));
        if (ingredient.amount <= 0 || ingredient.unit == IngredientUnit.toTaste) continue;
        final amount = ingredient.amount * household;
        line.amounts.update(ingredient.unit, (sum) => sum + amount, ifAbsent: () => amount);
      }
    }
    final sorted = lines.entries.toList()
      ..sort((a, b) {
        final byAisle = a.value.first.aisle.index.compareTo(b.value.first.aisle.index);
        return byAisle != 0
            ? byAisle
            : a.value.first.name.toLowerCase().compareTo(b.value.first.name.toLowerCase());
      });
    return [
      for (final (index, MapEntry(key: id, value: line)) in sorted.indexed)
        ShoppingItem(
          id: id,
          aisle: line.first.aisle,
          icon: line.first.icon,
          name: line.first.name,
          quantities: _merge(line.amounts),
          order: index,
        ),
    ];
  }

  /// Sums the amounts that share a base unit. A unit used alone keeps its
  /// own name ("3 c. à s."); mixed weights or volumes convert to g or ml.
  /// Counts never convert, so they stay separate parts.
  static List<Quantity> _merge(Map<IngredientUnit, double> amounts) {
    final byBase = <IngredientUnit, Map<IngredientUnit, double>>{};
    for (final MapEntry(key: unit, value: amount) in amounts.entries) {
      byBase.putIfAbsent(unit.baseUnit, () => {})[unit] = amount;
    }
    return [
      for (final MapEntry(key: base, value: units) in byBase.entries)
        units.length == 1
            ? Quantity(units.values.single, units.keys.single)
            : Quantity(units.entries.fold(0, (sum, e) => sum + e.value * e.key.factor), base),
    ];
  }

  /// A stable document id per ingredient. Spoonacular's id when there is
  /// one; otherwise the name, with anything but letters and digits as "_" so
  /// it can never form a path separator.
  static String _key(Ingredient ingredient) => ingredient.id > 0
      ? '${ingredient.id}'
      : 'name_${ingredient.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

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
