import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/theme/app_theme.dart';
import 'package:tably/features/home/cubit/home_cubit.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/preferences/service/profile_service.dart';
import 'package:tably/features/recipe/cubit/recipe_browse_cubit.dart';
import 'package:tably/features/recipe/cubit/recipe_cubit.dart';
import 'package:tably/features/recipe/cubit/recipe_search_cubit.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/features/recipe/screen/filters_screen.dart';
import 'package:tably/features/recipe/screen/recipes_screen.dart';
import 'package:tably/features/recipe/service/recipe_service.dart';
import 'package:tably/features/recipe/widget/filter_button.dart';
import 'package:tably/features/recipe/widget/recipe_row.dart';
import 'package:tably/l10n/app_localizations.dart';

import 'fixtures/recipe_fixtures.dart';

/// Holds Gemini's check until [release], so the searching state shows.
class _GatedAi extends FakeAi {
  final _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<({List<Recipe> recipes, int rejected})> adapt(List<Map<String, dynamic>> raw, UserProfile profile) async {
    await _gate.future;
    return super.adapt(raw, profile);
  }
}

/// Pumps the real recipes tab with real cubits; nothing is bound to a user,
/// so no Firebase call is made.
Future<void> _pumpRecipes(WidgetTester tester, {required FakeSearch api, required FakeAi ai}) async {
  tester.view.physicalSize = const Size(804, 1748);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  const analytics = AnalyticsService();
  final profileCubit = ProfileCubit(service: ProfileService(), analytics: analytics);
  final catalogueCubit = seededCatalogue(profileCubit);
  final recipeCubit = RecipeCubit(service: RecipeService(), analytics: analytics);
  final browseCubit = RecipeBrowseCubit(profileCubit: profileCubit, analytics: analytics);
  final searchCubit = RecipeSearchCubit(
    search: api,
    quota: unboundQuota(profileCubit),
    ai: ai,
    profileCubit: profileCubit,
    analytics: analytics,
  );
  for (final cubit in [searchCubit, browseCubit, recipeCubit, catalogueCubit, profileCubit]) {
    addTearDown(cubit.close);
  }

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: profileCubit),
        BlocProvider.value(value: catalogueCubit),
        BlocProvider.value(value: recipeCubit),
        BlocProvider.value(value: browseCubit),
        BlocProvider.value(value: searchCubit),
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
          home: const Scaffold(body: RecipesScreen()),
        ),
      ),
    ),
  );
  await profileCubit.completeOnboarding(const UserProfile());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('typing offers to search instead of saying nothing matches', (tester) async {
    final api = FakeSearch();
    final ai = _GatedAi();
    await _pumpRecipes(tester, api: api, ai: ai);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text('Rechercher « zzz »'), findsOneWidget);
    expect(find.textContaining('Aucun repas ne correspond'), findsNothing);
    expect(api.calls, isEmpty, reason: 'typing alone must not call the API');

    // The prompt searches; placeholder rows stand in until results arrive.
    await tester.tap(find.text('Rechercher « zzz »'));
    await tester.pump();
    expect(api.calls.single.query, 'en:zzz');
    expect(find.text('Recherche de recettes…'), findsOneWidget);
    expect(find.byType(RecipeRow), findsNothing);

    ai.release();
    await tester.pumpAndSettle();
    expect(find.text('Recherche de recettes…'), findsNothing);
    expect(find.byType(RecipeRow), findsWidgets);
    expect(find.text('Rechercher « zzz »'), findsNothing);
  });

  testWidgets('closing the filters searches with the new ones', (tester) async {
    final api = FakeSearch();
    await _pumpRecipes(tester, api: api, ai: FakeAi());
    // The test font is wider than the app's, so the filter chips overflow.
    final onError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.toString().contains('overflowed')) onError?.call(details);
    };

    await tester.tap(find.byType(FilterButton));
    await tester.pumpAndSettle();
    final browse = tester.element(find.byType(FiltersScreen)).read<RecipeBrowseCubit>();
    browse.toggleCuisine(Cuisine.values.first);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    FlutterError.onError = onError;

    expect(api.calls.single.cuisines, {Cuisine.values.first});
    expect(find.byType(RecipeRow), findsWidgets);
  });
}
