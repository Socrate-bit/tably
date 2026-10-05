import 'dart:async';
import 'dart:math';
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
import '../service/shopping_ai_service.dart';
import '../service/shopping_list_builder.dart';
import '../service/shopping_service.dart';

part 'shopping_state.dart';

/// Owns the shopping list. It is derived from the week, the household size
/// and the language, merged by Gemini, and rewritten whenever one of them
/// changes; ticks survive a rewrite.
/// Ticking an item updates the UI immediately and is rolled back if the write
/// fails.
class ShoppingCubit extends Cubit<ShoppingState> {
  ShoppingCubit({
    required ShoppingService service,
    required ShoppingAiService ai,
    required PlanCubit planCubit,
    required ProfileCubit profileCubit,
    required AnalyticsService analytics,
  })  : _service = service,
        _ai = ai,
        _planCubit = planCubit,
        _profileCubit = profileCubit,
        _analytics = analytics,
        super(const ShoppingState()) {
    _planSubscription = planCubit.stream.map((s) => (s.status, s.week)).distinct().listen((_) => _sync());
    _profileSubscription = profileCubit.stream
        .map((s) => (s.profile.household, s.profile.languageCode))
        .distinct()
        .listen((_) => _sync());
  }

  final ShoppingService _service;
  final ShoppingAiService _ai;
  final PlanCubit _planCubit;
  final ProfileCubit _profileCubit;
  final AnalyticsService _analytics;
  late final StreamSubscription<Object?> _planSubscription;
  late final StreamSubscription<Object?> _profileSubscription;
  StreamSubscription<List<ShoppingItem>>? _subscription;
  String? _uid;

  /// The source being built, so a slower, older build never overwrites it.
  String? _building;

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

  /// Rebuilds the list when what it is built from changed. Waits for the
  /// stored list, the plan settings and the recipes, so a half-loaded launch
  /// never wipes the list. When Gemini fails, the raw lines are stored
  /// unstamped so the next sync retries.
  Future<void> _sync() async {
    final uid = _uid;
    final plan = _planCubit.state;
    final profile = _profileCubit.state.profile;
    if (uid == null || state.status != ShoppingStatus.ready) return;
    if (plan.status != PlanStatus.ready || plan.week.slots.isEmpty) return;

    final source = ShoppingListBuilder.sourceOf(plan.week, profile.household, profile.languageCode);
    final derivedItems = state.items.where((i) => !i.manual);
    if (source == _building || (derivedItems.isNotEmpty && derivedItems.every((i) => i.source == source))) return;
    _building = source;
    emit(state.copyWith(updating: true));

    final lines = ShoppingListBuilder.linesFromWeek(plan.week, profile.household);
    List<ShoppingItem> derived;
    try {
      derived = await _ai.aggregate(lines, profile.languageCode, source);
    } catch (e) {
      debugPrint('[ShoppingCubit] merge failed, keeping raw lines: $e');
      derived = ShoppingAiService.merge(lines, const {}, '');
    }
    if (_building != source || isClosed) return;
    _building = null;

    // Ticks, deletions and edits carry over by id; the user's own items stay.
    final previous = state.items;
    final byId = {for (final i in previous) i.id: i};
    final next = [
      for (final i in derived)
        switch (byId[i.id]) {
          final mine? when mine.edited => mine.copyWith(source: i.source, order: i.order),
          final mine? => i.copyWith(checked: mine.checked, removed: mine.removed),
          null => i,
        },
      ...previous.where((i) => i.manual),
    ];
    final kept = {for (final i in next) i.id};
    emit(state.copyWith(items: next, updating: false, clearError: true));
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

  /// A new item the user adds, filed under [aisle] (the catch-all one by
  /// default).
  static ShoppingItem newItem({
    required String name,
    double amount = 0,
    IngredientUnit unit = IngredientUnit.piece,
    Aisle aisle = Aisle.herbsGrocery,
    String icon = '🛒',
  }) =>
      ShoppingItem(
        id: 'manual_${DateTime.now().microsecondsSinceEpoch}_${_added++}',
        aisle: aisle,
        icon: icon,
        name: name,
        amount: amount,
        unit: unit,
        source: '',
        order: 0,
        manual: true,
      );
  static int _added = 0;

  Future<bool> addItem(String name) => edit(add: [newItem(name: name)]);

  Future<bool> removeItem(String id) => edit(remove: {id});

  /// Applies the user's own changes in one write: [add] new items (see
  /// [newItem]), [remove] items by id, [update] the name, amount and unit of
  /// items by id, and tick [check] or untick [uncheck] items. Shows them at
  /// once; returns false and rolls back when the write fails.
  Future<bool> edit({
    List<ShoppingItem> add = const [],
    Set<String> remove = const {},
    List<ShoppingItem> update = const [],
    Set<String> check = const {},
    Set<String> uncheck = const {},
  }) async {
    final previous = state.items;
    final updates = {for (final u in update) u.id: u};
    final next = <ShoppingItem>[];
    final changed = <ShoppingItem>[];
    final deleted = <String>[];
    for (final item in previous) {
      var edited = item;
      if (remove.contains(item.id)) {
        // The user's own items go; derived ones hide, or a rebuild brings them back.
        if (item.manual) {
          deleted.add(item.id);
          continue;
        }
        edited = item.copyWith(removed: true);
      } else if (updates[item.id] case final u?) {
        edited = item.copyWith(name: u.name, amount: u.amount, unit: u.unit, edited: !item.manual);
      }
      if (check.contains(item.id)) edited = edited.copyWith(checked: true);
      if (uncheck.contains(item.id)) edited = edited.copyWith(checked: false);
      if (edited != item) changed.add(edited);
      next.add(edited);
    }
    var order = previous.fold(0, (top, i) => max(top, i.order + 1));
    for (final item in add) {
      final placed = item.copyWith(order: order++);
      next.add(placed);
      changed.add(placed);
    }
    if (changed.isEmpty && deleted.isEmpty) return true;

    emit(state.copyWith(items: next, clearError: true));
    final uid = _uid;
    if (uid == null) return true;
    try {
      await _service.replaceList(uid, changed, deleted);
      debugPrint('[ShoppingCubit] list edited: ${changed.length} changed, ${deleted.length} deleted');
      unawaited(_analytics.capture(AnalyticsEvents.shoppingListEdited, properties: {
        'added': add.length,
        'removed': remove.length,
        'updated': update.length,
        'checked': check.length + uncheck.length,
      }));
      return true;
    } catch (e) {
      debugPrint('[ShoppingCubit] edit failed: $e');
      emit(state.copyWith(items: previous, error: e));
      return false;
    }
  }

  /// Renders the list as plain text for copy and share, with [aisleName]
  /// and [amount] giving each aisle's heading and each item's amount in the
  /// user's language.
  String asPlainText(String Function(Aisle) aisleName, String Function(ShoppingItem) amount) => [
        for (final category in state.categories) ...[
          aisleName(category.aisle),
          for (final item in category.items)
            item.hasAmount ? '- ${item.name} (${amount(item)})' : '- ${item.name}',
          '',
        ],
      ].join('\n').trim();

  /// Opens the native share sheet with [header] above the list as text.
  /// Returns false on failure.
  Future<bool> share({
    required String subject,
    required String header,
    required String Function(Aisle) aisleName,
    required String Function(ShoppingItem) amount,
    Rect? origin,
  }) async {
    try {
      final result = await SharePlus.instance.share(ShareParams(
        text: '$header\n\n${asPlainText(aisleName, amount)}',
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
    _profileSubscription.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
