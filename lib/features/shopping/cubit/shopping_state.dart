part of 'shopping_cubit.dart';

enum ShoppingStatus { loading, ready, failed }

class ShoppingState extends Equatable {
  const ShoppingState({
    this.status = ShoppingStatus.loading,
    this.items = const [],
    this.error,
  });

  final ShoppingStatus status;
  final List<ShoppingItem> items;
  final Object? error;

  int get total => items.length;

  int get checkedCount => items.where((i) => i.checked).length;

  /// Items grouped into aisle cards, in catalogue order.
  List<ShoppingCategory> get categories => ShoppingCatalogue.groupByCategory(items);

  ShoppingState copyWith({
    ShoppingStatus? status,
    List<ShoppingItem>? items,
    Object? error,
    bool clearError = false,
  }) =>
      ShoppingState(
        status: status ?? this.status,
        items: items ?? this.items,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, items, error];
}
