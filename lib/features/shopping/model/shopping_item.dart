import 'package:equatable/equatable.dart';

import '../../../core/model/aisle.dart';
import '../../../core/model/ingredient_unit.dart';

/// One line on the shopping list, stored at `users/{uid}/shopping/{id}`.
class ShoppingItem extends Equatable {
  const ShoppingItem({
    required this.id,
    required this.aisle,
    required this.icon,
    required this.name,
    required this.amount,
    required this.unit,
    required this.source,
    required this.order,
    this.checked = false,
  });

  /// Derived from the ingredients it covers, so a rebuilt list keeps what
  /// was ticked.
  final String id;
  final Aisle aisle;
  final String icon;
  final String name;

  /// How much the week's recipes require, in one [unit]; 0 when they give
  /// no amount ("to taste").
  final double amount;
  final IngredientUnit unit;

  /// What the list was built from (see ShoppingListBuilder.sourceOf), so an
  /// unchanged week is never rebuilt. Empty when the merge failed, so the
  /// next sync retries it.
  final String source;

  /// Position within the list, aisle by aisle.
  final int order;
  final bool checked;

  /// Whether there is an amount worth showing.
  bool get hasAmount => amount > 0 && unit != IngredientUnit.toTaste;

  ShoppingItem copyWith({bool? checked}) => ShoppingItem(
    id: id,
    aisle: aisle,
    icon: icon,
    name: name,
    amount: amount,
    unit: unit,
    source: source,
    order: order,
    checked: checked ?? this.checked,
  );

  Map<String, dynamic> toMap() => {
    'aisle': aisle.id,
    'icon': icon,
    'name': name,
    'amount': amount,
    'unit': unit.id,
    'source': source,
    'order': order,
    'checked': checked,
  };

  factory ShoppingItem.fromMap(String id, Map<String, dynamic> map) => ShoppingItem(
    id: id,
    aisle: Aisle.fromId(map['aisle'] as String?),
    icon: map['icon'] as String? ?? '🛒',
    name: map['name'] as String? ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
    unit: IngredientUnit.fromId(map['unit'] as String?),
    source: map['source'] as String? ?? '',
    order: (map['order'] as num?)?.toInt() ?? 0,
    checked: map['checked'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, aisle, icon, name, amount, unit, source, order, checked];
}

/// Items of one aisle, ready to render as a card.
class ShoppingCategory extends Equatable {
  const ShoppingCategory({required this.aisle, required this.items});

  final Aisle aisle;
  final List<ShoppingItem> items;

  @override
  List<Object?> get props => [aisle, items];
}
