import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../model/shopping_item.dart';
import '../service/shopping_catalogue.dart';
import '../service/shopping_service.dart';

part 'shopping_state.dart';

/// Owns the shopping list. Ticking an item updates the UI immediately and is
/// rolled back if the write fails.
class ShoppingCubit extends Cubit<ShoppingState> {
  ShoppingCubit({required ShoppingService service, required AnalyticsService analytics})
      : _service = service,
        _analytics = analytics,
        super(const ShoppingState());

  final ShoppingService _service;
  final AnalyticsService _analytics;
  StreamSubscription<List<ShoppingItem>>? _subscription;
  String? _uid;

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    emit(state.copyWith(status: ShoppingStatus.loading, clearError: true));
    _subscription = _service.watch(uid).listen(
      (items) => emit(state.copyWith(status: ShoppingStatus.ready, items: items, clearError: true)),
      onError: (Object e) {
        debugPrint('[ShoppingCubit] stream error: $e');
        emit(state.copyWith(status: ShoppingStatus.failed, error: e));
      },
    );
  }

  /// Optimistically ticks or unticks an item.
  Future<void> toggle(ShoppingItem item) async {
    final uid = _uid;
    final next = !item.checked;
    final previous = state.items;

    emit(state.copyWith(
      items: [
        for (final i in previous) i.id == item.id ? i.copyWith(checked: next) : i,
      ],
      clearError: true,
    ));

    if (uid == null) return;
    try {
      await _service.setChecked(uid, item.id, next);
      unawaited(_analytics.capture(
        AnalyticsEvents.shoppingItemToggled,
        properties: {'checked': next},
      ));
    } catch (e) {
      debugPrint('[ShoppingCubit] toggle failed: $e');
      emit(state.copyWith(items: previous, error: e));
    }
  }

  /// Renders the list as plain text for copy and share.
  String asPlainText() => [
        for (final category in state.categories) ...[
          category.name,
          for (final item in category.items) '- ${item.name} (${item.quantity})',
          '',
        ],
      ].join('\n').trim();

  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
