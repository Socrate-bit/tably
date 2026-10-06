import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../service/review_service.dart';

class ReviewState extends Equatable {
  const ReviewState({this.isReady = false, this.inReview = false});

  /// False until the flag has been read once (or failed to be).
  final bool isReady;

  /// This build is in App Review: store choice and comparison, the AI chef
  /// and referral codes are hidden.
  final bool inReview;

  @override
  List<Object?> get props => [isReady, inReview];
}

/// Follows the remote App Review flag for the running build. Any failure
/// leaves every feature visible.
class ReviewCubit extends Cubit<ReviewState> {
  ReviewCubit({required ReviewService service}) : _service = service, super(const ReviewState());

  final ReviewService _service;
  StreamSubscription<List<String>>? _sub;

  Future<void> start() async {
    try {
      final build = await _service.currentBuild();
      _sub = _service.watchBuilds().listen(
        (builds) {
          final inReview = builds.contains(build);
          debugPrint('[ReviewCubit] build $build ${inReview ? 'is' : 'is not'} in review');
          emit(ReviewState(isReady: true, inReview: inReview));
        },
        onError: (Object e, StackTrace s) {
          AnalyticsService.reportError('ReviewCubit', 'watch', e, stack: s);
          emit(ReviewState(isReady: true, inReview: state.inReview));
        },
      );
    } catch (e, s) {
      AnalyticsService.reportError('ReviewCubit', 'start', e, stack: s);
      emit(const ReviewState(isReady: true));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
