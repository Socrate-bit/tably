part of 'shopping_cubit.dart';

enum ShoppingStatus { loading, ready, failed }

class ShoppingState extends Equatable {
  const ShoppingState({
    this.status = ShoppingStatus.loading,
    this.items = const [],
    this.updating = false,
    this.error,
  });

  final ShoppingStatus status;
  final List<ShoppingItem> items;

  /// True while the list is rebuilt for a changed week, household or
  /// language, before the new items land.
  final bool updating;
  final Object? error;

  /// What the list shows: everything but the items the user deleted.
  List<ShoppingItem> get visibleItems => [for (final i in items) if (!i.removed) i];

  int get total => visibleItems.length;

  int get checkedCount => visibleItems.where((i) => i.checked).length;

  /// Items grouped into aisle cards, in aisle order.
  List<ShoppingCategory> get categories => ShoppingListBuilder.groupByAisle(visibleItems);

  ShoppingState copyWith({
    ShoppingStatus? status,
    List<ShoppingItem>? items,
    bool? updating,
    Object? error,
    bool clearError = false,
  }) =>
      ShoppingState(
        status: status ?? this.status,
        items: items ?? this.items,
        updating: updating ?? this.updating,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, items, updating, error];
}
