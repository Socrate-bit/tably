import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/model/user_type.dart';
import 'package:tably/core/theme/app_theme.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/cubit/catalogue_cubit.dart';
import 'package:tably/features/recipe/cubit/recipe_browse_cubit.dart';
import 'package:tably/features/recipe/cubit/recipe_search_cubit.dart';
import 'package:tably/features/recipe/cubit/search_quota_cubit.dart';
import 'package:tably/features/recipe/widget/quota_dialog.dart';
import 'package:tably/l10n/app_localizations.dart';

import 'fixtures/recipe_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchQuotaState', () {
    const today = '2026-10-05';

    test('a count only applies on the day it was made', () {
      expect(const SearchQuotaState(today: today).remaining, 30, reason: 'never searched');
      expect(const SearchQuotaState(today: today, limit: 200, day: today, count: 30).remaining, 170);
      expect(const SearchQuotaState(today: today, day: '2026-10-04', count: 30).remaining, 30, reason: 'yesterday');
      expect(const SearchQuotaState(today: today, day: today, count: 4).remaining, 26);
      expect(const SearchQuotaState(today: today, day: today, count: 31).remaining, 0, reason: 'never negative');
    });

    test('resets at the next midnight UTC', () {
      expect(const SearchQuotaState(today: today).resetsAt, DateTime.utc(2026, 10, 6));
      expect(SearchQuotaState.utcDay(DateTime.utc(2026, 10, 5, 23, 59)), today);
    });
  });

  ProfileCubit profileCubit() {
    final cubit = ProfileCubit(service: ProfileService(), analytics: const AnalyticsService());
    addTearDown(cubit.close);
    return cubit;
  }

  test('a bound cubit follows the stored count', () async {
    final quota = await spentQuota(profileCubit(), used: 4);
    addTearDown(quota.close);
    expect(quota.state.remaining, 26);
    expect(quota.ensureAvailable, returnsNormally);
  });

  for (final type in [UserType.admin, UserType.ugc]) {
    test('${type.id} users get 200 searches a day', () async {
      final profile = profileCubit();
      final quota = await spentQuota(profile);
      addTearDown(quota.close);
      expect(quota.ensureAvailable, throwsA(isA<SearchLimitException>()), reason: 'a normal user is out');

      // The type arrives with the profile, as after redeeming a code.
      await profile.completeOnboarding(UserProfile(userType: type));
      await Future<void>.delayed(Duration.zero);

      expect(quota.state.limit, 200);
      expect(quota.state.remaining, 170);
      expect(quota.ensureAvailable, returnsNormally);
    });
  }

  group('with no search left', () {
    late SearchQuotaCubit quota;
    late ProfileCubit profile;

    setUp(() async {
      profile = profileCubit();
      quota = await spentQuota(profile);
      addTearDown(quota.close);
    });

    test('the recipes tab fails as a quota error without calling the API', () async {
      final api = FakeSearch();
      final ai = FakeAi();
      final search = RecipeSearchCubit(
        search: api,
        quota: quota,
        ai: ai,
        profileCubit: profile,
        analytics: const AnalyticsService(),
      );
      addTearDown(search.close);

      await search.search(const RecipeBrowseState(query: 'curry'));

      expect(api.calls, isEmpty);
      expect(ai.candidates, isEmpty);
      expect(search.state.status, RecipeSearchStatus.failed);
      expect(CatalogueCubit.reasonFor(search.state.error), 'quota');
    });

    test('a catalogue build fails as a quota error without calling the API', () async {
      final api = FakeSearch();
      final catalogue = seededCatalogue(profile, search: api, quota: quota);
      addTearDown(catalogue.close);

      expect(await catalogue.build(const UserProfile()), isFalse);
      expect(api.calls, isEmpty);
      expect(CatalogueCubit.reasonFor(catalogue.state.error), 'quota');
    });
  });

  test("the server's limit counts as the quota too", () {
    expect(CatalogueCubit.reasonFor(FirebaseFunctionsException(code: 'resource-exhausted', message: '')), 'quota');
  });

  group('showSearchError', () {
    Future<BuildContext> pump(WidgetTester tester, SearchQuotaCubit quota) async {
      late BuildContext context;
      await tester.pumpWidget(
        BlocProvider.value(
          value: quota,
          child: ScreenUtilInit(
            designSize: const Size(AppDimens.designWidth, AppDimens.designHeight),
            builder: (_, _) => MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: const [
                AppL10n.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppL10n.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (c) {
                    context = c;
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      return context;
    }

    testWidgets('pops up the limit and its reset time', (tester) async {
      final quota = await spentQuota(profileCubit());
      final context = await pump(tester, quota);

      showSearchError(context, const SearchLimitException());
      await tester.pumpAndSettle();

      expect(find.text('Search limit reached'), findsOneWidget);
      expect(find.textContaining("You've used your 30 recipe searches for today. They reset tomorrow at"), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Search limit reached'), findsNothing);
      await quota.close();
    });

    testWidgets('keeps the banner for other failures', (tester) async {
      final context = await pump(tester, unboundQuota(profileCubit()));

      showSearchError(context, Exception('offline'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(QuotaDialog), findsNothing);
    });
  });
}
