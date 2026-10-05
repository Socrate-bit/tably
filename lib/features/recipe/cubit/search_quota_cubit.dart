import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/model/user_type.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../service/search_quota_service.dart';

part 'search_quota_state.dart';

/// Thrown before a search when today's are all spent, so no call is made.
class SearchLimitException implements Exception {
  const SearchLimitException();

  @override
  String toString() => 'SearchLimitException: daily search limit reached';
}

/// Tracks how many of the day's recipe searches the user has left: 30, or
/// 200 for admins and creators. The server enforces the limit; this streams
/// its count, follows the user's type, and rolls over to a fresh day at
/// midnight UTC while the app is open.
class SearchQuotaCubit extends Cubit<SearchQuotaState> {
  SearchQuotaCubit({
    required SearchQuotaService service,
    required ProfileCubit profileCubit,
    required AnalyticsService analytics,
  })  : _service = service,
        _analytics = analytics,
        super(SearchQuotaState(
          today: SearchQuotaState.utcDay(DateTime.now()),
          limit: profileCubit.state.profile.userType.dailySearches,
        )) {
    _typeSubscription = profileCubit.stream
        .map((s) => s.profile.userType)
        .distinct()
        .listen((type) => emit(state.copyWith(limit: type.dailySearches)));
  }

  final SearchQuotaService _service;
  final AnalyticsService _analytics;
  late final StreamSubscription<UserType> _typeSubscription;
  StreamSubscription<({String? day, int count})>? _subscription;
  Timer? _rollover;
  String? _uid;

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    _rollover ??= _scheduleRollover();
    _subscription = _service.watch(uid).listen(
          (usage) => emit(state.copyWith(day: usage.day, count: usage.count)),
          onError: (Object e) => debugPrint('[SearchQuotaCubit] stream error: $e'),
        );
  }

  /// Throws [SearchLimitException] when no search is left today.
  void ensureAvailable() {
    if (state.remaining > 0) return;
    debugPrint('[SearchQuotaCubit] search blocked, limit reached');
    throw const SearchLimitException();
  }

  /// The user opened the counter's explanation.
  void opened() =>
      unawaited(_analytics.capture(AnalyticsEvents.searchQuotaOpened, properties: {'remaining': state.remaining}));

  /// Moves to the new UTC day just after midnight, freeing the day's searches.
  Timer _scheduleRollover() => _rollover = Timer(
        state.resetsAt.difference(DateTime.now()) + const Duration(seconds: 1),
        () {
          emit(state.copyWith(today: SearchQuotaState.utcDay(DateTime.now())));
          _scheduleRollover();
        },
      );

  @override
  Future<void> close() {
    _typeSubscription.cancel();
    _subscription?.cancel();
    _rollover?.cancel();
    return super.close();
  }
}
