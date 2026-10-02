import 'dart:async';
import 'dart:ui' show Rect;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/model/aisle.dart';
import '../../../core/model/ingredient_unit.dart';
import '../../plan/cubit/plan_cubit.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../model/shopping_item.dart';
import '../service/shopping_list_builder.dart';
import '../service/shopping_service.dart';

part 'shopping_state.dart';

/// Owns the shopping list. It is derived from the week and the household
/// size and rewritten whenever either changes; ticks survive a rewrite.
/// Ticking an item updates the UI immediately and is rolled back if the write
/// fails.
class ShoppingCubit extends Cubit<ShoppingState> {
  ShoppingCubit({
    required ShoppingService service,
    required PlanCubit planCubit,
    required ProfileCubit profileCubit,
    required AnalyticsService analytics,
  })  : _service = service,
        _planCubit = planCubit,
        _profileCubit = profileCubit,
        _analytics = analytics,
        super(const ShoppingState()) {
    _planSubscription = planCubit.stream.map((s) => (s.status, s.week)).distinct().listen((_) => _sync());
    _householdSubscription =
        profileCubit.stream.map((s) => s.profile.household).distinct().listen((_) => _sync());
  }

  final ShoppingService _service;
  final PlanCubit _planCubit;
  final ProfileCubit _profileCubit;
  final AnalyticsService _analytics;
  late final StreamSubscription<Object?> _planSubscription;
  late final StreamSubscription<Object?> _householdSubscription;
  StreamSubscription<List<ShoppingItem>>? _subscription;
  String? _uid;

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    emit(state.copyWith(status: ShoppingStatus.loading, clearError: true));
    _subscription = _service.watch(uid).listen(
      (items) {
        final firstLoad = state.status == ShoppingStatus.loading;
        emit(state.copyWith(status: ShoppingStatus.ready, items: items, clearError: true));
        if (firstLoad) _sync();
      },
      onError: (Object e) {
        debugPrint('[ShoppingCubit] stream error: $e');
        emit(state.copyWith(status: ShoppingStatus.failed, error: e));
      },
    );
  }

  /// Rewrites the list when the week's ingredients differ from it. Waits for
  /// the stored list, the plan settings and the recipes, so a half-loaded
  /// launch never wipes the list; and skips the write when nothing changed.
  Future<void> _sync() async {
    final uid = _uid;
    final plan = _planCubit.state;
    if (uid == null || state.status != ShoppingStatus.ready) return;
    if (plan.status != PlanStatus.ready || plan.week.slots.isEmpty) return;

    final derived = ShoppingListBuilder.fromWeek(plan.week, _profileCubit.state.profile.household);
    final previous = state.items;
    List<ShoppingItem> unchecked(List<ShoppingItem> items) => [for (final i in items) i.copyWith(checked: false)];
    if (listEquals(unchecked(derived), unchecked(previous))) return;

    final ticked = {for (final i in previous) if (i.checked) i.id};
    final next = [for (final i in derived) i.copyWith(checked: ticked.contains(i.id))];
    final kept = {for (final i in next) i.id};
    emit(state.copyWith(items: next, clearError: true));
    try {
      await _service.replaceList(uid, next, previous.map((i) => i.id).where((id) => !kept.contains(id)));
    } catch (e) {
      debugPrint('[ShoppingCubit] sync failed: $e');
      emit(state.copyWith(items: previous, error: e));
    }
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

  /// Renders the list as plain text for copy and share, with [aisleName]
  /// and [quantities] giving each aisle's heading and each item's amount in
  /// the user's language.
  String asPlainText(String Function(Aisle) aisleName, String Function(List<Quantity>) quantities) => [
        for (final category in state.categories) ...[
          aisleName(category.aisle),
          for (final item in category.items)
            item.quantities.isEmpty ? '- ${item.name}' : '- ${item.name} (${quantities(item.quantities)})',
          '',
        ],
      ].join('\n').trim();

  /// Opens the native share sheet with the list as text. Returns false on failure.
  Future<bool> share({
    required String subject,
    required String Function(Aisle) aisleName,
    required String Function(List<Quantity>) quantities,
    Rect? origin,
  }) async {
    try {
      final result = await SharePlus.instance.share(ShareParams(
        text: asPlainText(aisleName, quantities),
        subject: subject,
        sharePositionOrigin: origin,
      ));
      debugPrint('[ShoppingCubit] share sheet closed: ${result.status}');
      unawaited(_analytics.capture(
        AnalyticsEvents.shoppingListShared,
        properties: {'status': result.status.name},
      ));
      return true;
    } catch (e) {
      debugPrint('[ShoppingCubit] share failed: $e');
      return false;
    }
  }

  void errorShown() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _planSubscription.cancel();
    _householdSubscription.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
