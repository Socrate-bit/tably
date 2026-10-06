import 'package:tably/features/review/cubit/review_cubit.dart';
import 'package:tably/features/review/service/review_service.dart';

/// Stands in for Firestore and the platform: this install is build 0.1.0.3,
/// and [builds] are the ones flagged for review.
class FakeReviewService extends ReviewService {
  FakeReviewService(this.builds);

  final List<String> builds;

  @override
  Future<String> currentBuild() async => '0.1.0.3';

  @override
  Stream<List<String>> watchBuilds() => Stream.value(builds);
}

/// A started [ReviewCubit] whose build is, or is not, in App Review.
Future<ReviewCubit> startedReview({required bool inReview}) async {
  final cubit = ReviewCubit(service: FakeReviewService([if (inReview) '0.1.0.3']));
  await cubit.start();
  await cubit.stream.firstWhere((s) => s.isReady);
  return cubit;
}
