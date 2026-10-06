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

  test('onboarding skips the store choice and the savings promise in review', () async {
    final cubit = await _onboarding(inReview: true);

    expect(cubit.state.steps.map((s) => s.id), isNot(anyOf(contains(StepIds.store), contains(StepIds.infoMoney))));
    expect(cubit.state.copyWith(inReview: false).steps.map((s) => s.id), containsAll([StepIds.store, StepIds.infoMoney]));
  });

  for (final inReview in [false, true]) {
    test(
      'onboarding ${inReview ? 'skips' : 'shows'} the rating prompt ${inReview ? 'in' : 'outside'} review',
      () async {
        final cubit = await _onboarding(inReview: inReview);
        _answerEveryStep(cubit);
        cubit.next();

        expect(cubit.state.phase, inReview ? OnboardingPhase.generating : OnboardingPhase.rating);
      },
    );
  }
}

/// An onboarding cubit on fakes, closed with the test.
Future<OnboardingCubit> _onboarding({required bool inReview}) async {
  final profileCubit = ProfileCubit(service: ProfileService(), analytics: const AnalyticsService());
  final catalogue = seededCatalogue(profileCubit);
  final review = await startedReview(inReview: inReview);
  final cubit = OnboardingCubit(catalogueCubit: catalogue, reviewCubit: review, analytics: const AnalyticsService());
  addTearDown(profileCubit.close);
  addTearDown(catalogue.close);
  addTearDown(review.close);
  addTearDown(cubit.close);
  return cubit;
}

/// Walks to the last step, giving every required answer on the way.
void _answerEveryStep(OnboardingCubit cubit) {
  while (!cubit.state.isLastStep) {
    final step = cubit.state.currentStep;
    if (step.id == StepIds.name) cubit.setName('Chef');
    if (step.options.isNotEmpty) cubit.select(step.options.first.id);
    cubit.next();
    expect(cubit.state.currentStep, isNot(step), reason: 'stuck on ${step.id}');
  }
}
