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
    this.manual = false,
    this.removed = false,
    this.edited = false,
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

  /// Added by the user rather than derived from the week; never touched by
  /// a rebuild.
  final bool manual;

  /// A derived item the user deleted. Hidden, and kept hidden by rebuilds
  /// for as long as the week still needs it.
  final bool removed;

  /// A derived item whose name or amount the user changed; rebuilds keep
  /// their version.
  final bool edited;

  /// Whether there is an amount worth showing.
  bool get hasAmount => amount > 0 && unit != IngredientUnit.toTaste;

  ShoppingItem copyWith({
    String? name,
    double? amount,
    IngredientUnit? unit,
    String? source,
    int? order,
    bool? checked,
    bool? removed,
    bool? edited,
  }) =>
      ShoppingItem(
        id: id,
        aisle: aisle,
        icon: icon,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        unit: unit ?? this.unit,
        source: source ?? this.source,
        order: order ?? this.order,
        checked: checked ?? this.checked,
        manual: manual,
        removed: removed ?? this.removed,
        edited: edited ?? this.edited,
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
    if (manual) 'manual': true,
    if (removed) 'removed': true,
    if (edited) 'edited': true,
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
    manual: map['manual'] as bool? ?? false,
    removed: map['removed'] as bool? ?? false,
    edited: map['edited'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, aisle, icon, name, amount, unit, source, order, checked, manual, removed, edited];
}

/// Items of one aisle, ready to render as a card.
class ShoppingCategory extends Equatable {
  const ShoppingCategory({required this.aisle, required this.items});

  final Aisle aisle;
  final List<ShoppingItem> items;

  @override
  List<Object?> get props => [aisle, items];
}
