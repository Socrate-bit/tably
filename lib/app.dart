import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/analytics/analytics_service.dart';
import 'core/theme/app_theme.dart';
import 'features/account/cubit/auth_cubit.dart';
import 'features/account/service/auth_service.dart';
import 'features/home/cubit/home_cubit.dart';
import 'features/onboarding/cubit/onboarding_cubit.dart';
import 'features/plan/cubit/plan_cubit.dart';
import 'features/plan/service/plan_service.dart';
import 'features/preferences/cubit/profile_cubit.dart';
import 'features/preferences/service/profile_service.dart';
import 'features/recipe/cubit/recipe_cubit.dart';
import 'features/recipe/service/recipe_service.dart';
import 'features/shopping/cubit/shopping_cubit.dart';
import 'features/shopping/service/shopping_service.dart';
import 'l10n/app_localizations.dart';
import 'root.dart';

/// Wires up services and cubits, then hands off to [RootScreen].
class TablyApp extends StatelessWidget {
  const TablyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const analytics = AnalyticsService();
    final recipeService = RecipeService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AnalyticsService>.value(value: analytics),
        RepositoryProvider(create: (_) => AuthService()),
        RepositoryProvider(create: (_) => ProfileService()),
        RepositoryProvider(create: (_) => PlanService()),
        RepositoryProvider(create: (_) => ShoppingService()),
        RepositoryProvider<RecipeService>.value(value: recipeService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthCubit(
              authService: context.read<AuthService>(),
              analytics: analytics,
            )..start(),
          ),
          BlocProvider(
            create: (context) => ProfileCubit(
              service: context.read<ProfileService>(),
              analytics: analytics,
            ),
          ),
          BlocProvider(
            create: (context) => PlanCubit(
              planService: context.read<PlanService>(),
              shoppingService: context.read<ShoppingService>(),
              analytics: analytics,
            ),
          ),
          BlocProvider(
            create: (context) => ShoppingCubit(
              service: context.read<ShoppingService>(),
              analytics: analytics,
            ),
          ),
          BlocProvider(
            create: (context) => RecipeCubit(service: recipeService, analytics: analytics),
          ),
          BlocProvider(create: (_) => OnboardingCubit(analytics: analytics)),
          BlocProvider(create: (_) => HomeCubit(analytics: analytics)),
        ],
        child: ScreenUtilInit(
          // The design was drawn at 402x860.
          designSize: const Size(AppDimens.designWidth, AppDimens.designHeight),
          minTextAdapt: true,
          builder: (context, _) => BlocBuilder<ProfileCubit, ProfileState>(
            // The profile owns the chosen language, so the app rebuilds on change.
            buildWhen: (previous, current) =>
                previous.profile.languageCode != current.profile.languageCode,
            builder: (context, state) => MaterialApp(
              title: 'Tably',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.build(),
              locale: Locale(state.profile.languageCode),
              localizationsDelegates: const [
                AppL10n.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppL10n.supportedLocales,
              home: const RootScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
