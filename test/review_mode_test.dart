import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:tably/features/onboarding/model/onboarding_step.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/review/service/review_service.dart';

import 'fixtures/recipe_fixtures.dart';
import 'fixtures/review_fixtures.dart';

void main() {
  test('only a build listed in settings/review is in review', () async {
    final listed = await startedReview(inReview: true);
    final other = await startedReview(inReview: false);
    addTearDown(listed.close);
    addTearDown(other.close);

    expect(listed.state.inReview, isTrue);
    expect(other.state.inReview, isFalse);
  });

  test('app_version may hold one build or a list of them', () {
    expect(ReviewService.buildsFrom('0.1.0.3'), ['0.1.0.3']);
    expect(ReviewService.buildsFrom(['0.1.0.2', '0.1.0.3']), ['0.1.0.2', '0.1.0.3']);
    expect(ReviewService.buildsFrom(null), isEmpty);
  });

  test('onboarding skips the store choice in review', () async {
    final profileCubit = ProfileCubit(service: ProfileService(), analytics: const AnalyticsService());
    final catalogue = seededCatalogue(profileCubit);
    final review = await startedReview(inReview: true);
    final cubit = OnboardingCubit(catalogueCubit: catalogue, reviewCubit: review, analytics: const AnalyticsService());
    addTearDown(profileCubit.close);
    addTearDown(catalogue.close);
    addTearDown(review.close);
    addTearDown(cubit.close);

    expect(cubit.state.steps.map((s) => s.id), isNot(contains(StepIds.store)));
    expect(cubit.state.copyWith(inReview: false).steps.map((s) => s.id), contains(StepIds.store));
  });
}
