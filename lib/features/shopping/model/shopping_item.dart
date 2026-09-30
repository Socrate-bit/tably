import 'package:equatable/equatable.dart';

import '../../../core/model/aisle.dart';

/// One line on the shopping list, stored at `users/{uid}/shopping/{id}`.
class ShoppingItem extends Equatable {
  const ShoppingItem({
    required this.id,
    required this.aisle,
    required this.icon,
    required this.name,
    required this.needed,
    required this.order,
    this.checked = false,
  });

  /// Ingredient id and unit, so a rebuilt list keeps what was ticked.
  final String id;
  final Aisle aisle;
  final String icon;
  final String name;

  /// How much the week's recipes require, e.g. "350g"; empty when the
  /// recipes give no amount ("to taste").
  final String needed;

  /// Position within the list, aisle by aisle.
  final int order;
  final bool checked;

  ShoppingItem copyWith({bool? checked}) => ShoppingItem(
        id: id,
        aisle: aisle,
        icon: icon,
        name: name,
        needed: needed,
        order: order,
        checked: checked ?? this.checked,
      );

  Map<String, dynamic> toMap() => {
        'aisle': aisle.id,
        'icon': icon,
        'name': name,
        'needed': needed,
        'order': order,
        'checked': checked,
      };

  factory ShoppingItem.fromMap(String id, Map<String, dynamic> map) => ShoppingItem(
        id: id,
        aisle: Aisle.fromId(map['aisle'] as String?),
        icon: map['icon'] as String? ?? '🛒',
        name: map['name'] as String? ?? '',
        needed: map['needed'] as String? ?? '',
        order: (map['order'] as num?)?.toInt() ?? 0,
        checked: map['checked'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, aisle, icon, name, needed, order, checked];
}

/// Items of one aisle, ready to render as a card.
class ShoppingCategory extends Equatable {
  const ShoppingCategory({required this.aisle, required this.items});

  final Aisle aisle;
  final List<ShoppingItem> items;

  @override
  List<Object?> get props => [aisle, items];
}
