import '../../../core/model/aisle.dart';
import '../../../core/util/quantity.dart';
import '../../plan/model/week_plan.dart';
import '../model/shopping_item.dart';

/// Derives the shopping list from the week. Pure, so the same week always
/// gives the same list.
abstract final class ShoppingListBuilder {
  /// Every ingredient the week needs, summed across meals: each slot is one
  /// portion per household member, leftovers included since they are cooked
  /// in the same pot. The same ingredient in the same unit merges into one
  /// line. Sorted by aisle, then name.
  static List<ShoppingItem> fromWeek(WeekPlan week, int household) {
    final totals = <String, ({String name, String icon, Aisle aisle, String unit, double amount})>{};
    for (final slot in week.slots) {
      for (final ingredient in slot.recipe.ingredients) {
        final id = _key(ingredient.id, ingredient.unit);
        final previous = totals[id];
        totals[id] = (
          name: previous?.name ?? ingredient.name,
          icon: previous?.icon ?? ingredient.icon,
          aisle: previous?.aisle ?? ingredient.aisle,
          unit: ingredient.unit,
          amount: (previous?.amount ?? 0) + ingredient.amount * household,
        );
      }
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) {
        final byAisle = a.value.aisle.index.compareTo(b.value.aisle.index);
        return byAisle != 0 ? byAisle : a.value.name.toLowerCase().compareTo(b.value.name.toLowerCase());
      });
    return [
      for (final (index, MapEntry(key: id, value: line)) in sorted.indexed)
        ShoppingItem(
          id: id,
          aisle: line.aisle,
          icon: line.icon,
          name: line.name,
          needed: line.amount > 0 ? formatQuantity(line.amount, line.unit) : '',
          order: index,
        ),
    ];
  }

  /// A stable document id per ingredient and unit. Anything but letters and
  /// digits becomes "_", so a unit can never form a path separator.
  static String _key(int ingredientId, String unit) =>
      '${ingredientId}_${unit.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

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
