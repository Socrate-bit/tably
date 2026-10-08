import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/theme/app_theme.dart';
import 'package:tably/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:tably/features/onboarding/model/onboarding_step.dart';
import 'package:tably/features/onboarding/widget/steps/simple_steps.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/review/service/review_service.dart';
import 'package:tably/l10n/app_localizations.dart';

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

  test('a bare version covers every build of it', () {
    expect(ReviewService.covers('0.1.0.3', '0.1.0.3'), isTrue);
    expect(ReviewService.covers('0.1.0', '0.1.0.3'), isTrue);
    expect(ReviewService.covers('0.1.0.2', '0.1.0.3'), isFalse);
    expect(ReviewService.covers('0.1.1', '0.1.0.3'), isFalse);
    expect(ReviewService.covers('0.1', '0.1.0.3'), isFalse);
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

  for (final inReview in [false, true]) {
    testWidgets('the testimonials ${inReview ? 'hide' : 'show'} the user count ${inReview ? 'in' : 'outside'} review',
        (tester) async {
      tester.view.physicalSize = const Size(804, 1748);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(AppDimens.designWidth, AppDimens.designHeight),
        builder: (context, _) => MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: TestimonialStep(showUserCount: !inReview))),
        ),
      ));

      expect(find.textContaining('500 000'), inReview ? findsNothing : findsOneWidget);
    });
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
