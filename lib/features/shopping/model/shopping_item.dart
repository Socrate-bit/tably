import 'package:equatable/equatable.dart';

/// One line on the shopping list, stored at `users/{uid}/shopping/{id}`.
class ShoppingItem extends Equatable {
  const ShoppingItem({
    required this.id,
    required this.category,
    required this.icon,
    required this.name,
    required this.needed,
    required this.quantity,
    required this.order,
    this.checked = false,
  });

  final String id;

  /// Aisle grouping, e.g. "FRUITS ET LÉGUMES". Comes from the catalogue data.
  final String category;
  final String icon;
  final String name;

  /// How much the week's recipes require, e.g. "350g".
  final String needed;

  /// The pack size the user actually buys, e.g. "1 bag".
  final String quantity;

  /// Preserves catalogue ordering inside a category.
  final int order;
  final bool checked;

  ShoppingItem copyWith({bool? checked}) => ShoppingItem(
        id: id,
        category: category,
        icon: icon,
        name: name,
        needed: needed,
        quantity: quantity,
        order: order,
        checked: checked ?? this.checked,
      );

  Map<String, dynamic> toMap() => {
        'category': category,
        'icon': icon,
        'name': name,
        'needed': needed,
        'quantity': quantity,
        'order': order,
        'checked': checked,
      };

  factory ShoppingItem.fromMap(String id, Map<String, dynamic> map) => ShoppingItem(
        id: id,
        category: map['category'] as String? ?? '',
        icon: map['icon'] as String? ?? '🛒',
        name: map['name'] as String? ?? '',
        needed: map['needed'] as String? ?? '',
        quantity: map['quantity'] as String? ?? '',
        order: (map['order'] as num?)?.toInt() ?? 0,
        checked: map['checked'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, category, icon, name, needed, quantity, order, checked];
}

/// Items of one aisle, ready to render as a card.
class ShoppingCategory extends Equatable {
  const ShoppingCategory({required this.name, required this.items});

  final String name;
  final List<ShoppingItem> items;

  @override
  List<Object?> get props => [name, items];
}
