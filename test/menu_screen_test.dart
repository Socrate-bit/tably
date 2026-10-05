import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/theme/app_theme.dart';
import 'package:tably/features/home/cubit/home_cubit.dart';
import 'package:tably/features/plan/cubit/plan_cubit.dart';
import 'package:tably/features/plan/screen/menu_screen.dart';
import 'package:tably/features/plan/service/plan_service.dart';
import 'package:tably/features/plan/widget/meal_slot_card.dart';
import 'package:tably/features/plan/widget/plan_summary_cards.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/cubit/recipe_cubit.dart';
import 'package:tably/features/recipe/service/recipe_service.dart';
import 'package:tably/features/shopping/cubit/shopping_cubit.dart';
import 'package:tably/features/shopping/service/shopping_ai_service.dart';
import 'package:tably/features/shopping/service/shopping_service.dart';
import 'package:tably/l10n/app_localizations.dart';

import 'fixtures/recipe_fixtures.dart';

/// Pumps the real menu with real cubits; nothing is bound to a user, so no
/// Firebase call is made.
Future<ProfileCubit> _pumpMenu(WidgetTester tester, {required Size physicalSize, required UserProfile profile}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  const analytics = AnalyticsService();
  final profileCubit = ProfileCubit(service: ProfileService(), analytics: analytics);
  final catalogueCubit = seededCatalogue(profileCubit);
  final recipeCubit = RecipeCubit(service: RecipeService(), analytics: analytics);
  final planCubit = PlanCubit(
    service: PlanService(),
    profileCubit: profileCubit,
    catalogueCubit: catalogueCubit,
    recipeCubit: recipeCubit,
    analytics: analytics,
  );
  addTearDown(planCubit.close);
  addTearDown(recipeCubit.close);
  addTearDown(catalogueCubit.close);
  addTearDown(profileCubit.close);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: profileCubit),
        BlocProvider.value(value: catalogueCubit),
        BlocProvider.value(value: planCubit),
        BlocProvider(
          create: (_) => ShoppingCubit(
            service: ShoppingService(),
            ai: ShoppingAiService(),
            planCubit: planCubit,
            profileCubit: profileCubit,
            analytics: analytics,
          ),
        ),
        BlocProvider(create: (_) => HomeCubit(analytics: analytics)),
      ],
      child: ScreenUtilInit(
        designSize: const Size(AppDimens.designWidth, AppDimens.designHeight),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppL10n.supportedLocales,
          home: const Scaffold(body: MenuScreen()),
        ),
      ),
    ),
  );
  // Completing onboarding without a uid updates state locally only.
  await profileCubit.completeOnboarding(profile);
  await tester.pumpAndSettle();
  return profileCubit;
}

void main() {
  // The design frame, and the short viewport that once hid every meal card.
  for (final size in const [Size(804, 1748), Size(688, 672)]) {
    testWidgets('lays out lunch, dinner and leftovers at $size', (tester) async {
      await _pumpMenu(tester, physicalSize: size, profile: const UserProfile(mealsPerDay: 2, variety: Variety.balanced));

      expect(tester.takeException(), isNull);
      expect(find.text('LUNDI'), findsOneWidget);
      expect(find.text('DIMANCHE'), findsOneWidget);
      expect(find.text('DÉJEUNER'), findsNWidgets(7));
      expect(find.text('DÎNER'), findsNWidgets(7));
      // Seven recipes over fourteen meals: every pot feeds one leftover.
      expect(find.text('♻ Reste'), findsNWidgets(7));
      expect(find.textContaining('14 repas ·'), findsOneWidget);

      final cards = find.byType(MealSlotCard);
      expect(cards, findsNWidgets(14));
      final first = tester.getRect(cards.first);
      final second = tester.getRect(cards.at(1));
      expect(first.height, greaterThan(40), reason: 'meal card collapsed');
      expect(second.top, greaterThan(first.top), reason: 'meal cards overlap');
      expect(first.top, greaterThan(tester.getRect(find.byType(CostCard)).bottom), reason: 'meals must sit below the summary');
    });
  }

  testWidgets('shows only dinners, with no slot names, for one meal a day', (tester) async {
    await _pumpMenu(tester, physicalSize: const Size(804, 1748), profile: const UserProfile());

    expect(tester.takeException(), isNull);
    expect(find.byType(MealSlotCard), findsNWidgets(7));
    expect(find.text('DÎNER'), findsNothing);
    expect(find.text('♻ Reste'), findsNothing);
  });

  testWidgets('reflows immediately when meals per day changes', (tester) async {
    final profile = await _pumpMenu(tester, physicalSize: const Size(804, 1748), profile: const UserProfile());
    expect(find.byType(MealSlotCard), findsNWidgets(7));

    await profile.setMealsPerDay(2);
    await tester.pumpAndSettle();

    expect(find.byType(MealSlotCard), findsNWidgets(14));
    expect(find.text('DÉJEUNER'), findsNWidgets(7));
  });
}
