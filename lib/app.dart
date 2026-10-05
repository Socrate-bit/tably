import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/analytics/analytics_service.dart';
import 'core/theme/app_theme.dart';
import 'features/account/cubit/auth_cubit.dart';
import 'features/account/service/auth_service.dart';
import 'features/chat/cubit/chat_cubit.dart';
import 'features/chat/service/chat_agent_service.dart';
import 'features/chat/service/chat_service.dart';
import 'features/chat/tool/chat_tools.dart';
import 'features/home/cubit/home_cubit.dart';
import 'features/onboarding/cubit/onboarding_cubit.dart';
import 'features/plan/cubit/plan_cubit.dart';
import 'features/plan/service/plan_service.dart';
import 'features/preferences/cubit/profile_cubit.dart';
import 'features/preferences/service/profile_service.dart';
import 'features/recipe/cubit/catalogue_cubit.dart';
import 'features/recipe/cubit/recipe_browse_cubit.dart';
import 'features/recipe/cubit/recipe_cubit.dart';
import 'features/recipe/cubit/recipe_search_cubit.dart';
import 'features/recipe/cubit/search_quota_cubit.dart';
import 'features/recipe/service/recipe_ai_service.dart';
import 'features/recipe/service/recipe_search_service.dart';
import 'features/recipe/service/recipe_service.dart';
import 'features/recipe/service/search_quota_service.dart';
import 'features/shopping/cubit/shopping_cubit.dart';
import 'features/shopping/service/shopping_ai_service.dart';
import 'features/shopping/service/shopping_service.dart';
import 'features/subscription/cubit/subscription_cubit.dart';
import 'features/subscription/service/paywall_service.dart';
import 'features/subscription/service/referral_service.dart';
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
        RepositoryProvider(create: (_) => RecipeSearchService()),
        RepositoryProvider(create: (_) => SearchQuotaService()),
        RepositoryProvider(create: (_) => RecipeAiService()),
        RepositoryProvider(create: (_) => ShoppingAiService()),
        RepositoryProvider(create: (_) => const PaywallService()),
        RepositoryProvider(create: (_) => ReferralService()),
        RepositoryProvider(create: (_) => ChatService()),
        RepositoryProvider(create: (_) => ChatAgentService()),
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
            create: (context) => SubscriptionCubit(
              paywall: context.read<PaywallService>(),
              referral: context.read<ReferralService>(),
              profileCubit: context.read<ProfileCubit>(),
              analytics: analytics,
            ),
          ),
          BlocProvider(
            create: (context) => SearchQuotaCubit(
              service: context.read<SearchQuotaService>(),
              profileCubit: context.read<ProfileCubit>(),
              analytics: analytics,
            ),
          ),
          BlocProvider(
            create: (context) => CatalogueCubit(
              service: recipeService,
              search: context.read<RecipeSearchService>(),
              quota: context.read<SearchQuotaCubit>(),
              ai: context.read<RecipeAiService>(),
              profileCubit: context.read<ProfileCubit>(),
              analytics: analytics,
            ),
          ),
          BlocProvider(
            create: (context) => RecipeCubit(service: recipeService, analytics: analytics),
          ),
          BlocProvider(
            create: (context) => PlanCubit(
              service: context.read<PlanService>(),
              profileCubit: context.read<ProfileCubit>(),
              catalogueCubit: context.read<CatalogueCubit>(),
              recipeCubit: context.read<RecipeCubit>(),
              analytics: analytics,
            ),
          ),
          BlocProvider(
            create: (context) => ShoppingCubit(
              service: context.read<ShoppingService>(),
              ai: context.read<ShoppingAiService>(),
              planCubit: context.read<PlanCubit>(),
              profileCubit: context.read<ProfileCubit>(),
              analytics: analytics,
            ),
          ),
          BlocProvider(
            create: (context) => RecipeBrowseCubit(profileCubit: context.read<ProfileCubit>(), analytics: analytics),
          ),
          BlocProvider(
            create: (context) => RecipeSearchCubit(
              search: context.read<RecipeSearchService>(),
              quota: context.read<SearchQuotaCubit>(),
              ai: context.read<RecipeAiService>(),
              profileCubit: context.read<ProfileCubit>(),
              analytics: analytics,
            ),
          ),
          BlocProvider(
            create: (context) => OnboardingCubit(catalogueCubit: context.read<CatalogueCubit>(), analytics: analytics),
          ),
          BlocProvider(create: (_) => HomeCubit(analytics: analytics)),
          BlocProvider(
            create: (context) => ChatCubit(
              service: context.read<ChatService>(),
              agent: context.read<ChatAgentService>(),
              tools: ChatTools(
                profile: context.read<ProfileCubit>(),
                catalogue: context.read<CatalogueCubit>(),
                plan: context.read<PlanCubit>(),
                recipes: context.read<RecipeCubit>(),
                shopping: context.read<ShoppingCubit>(),
                search: context.read<RecipeSearchService>(),
                ai: context.read<RecipeAiService>(),
                analytics: analytics,
              ),
              analytics: analytics,
            ),
          ),
        ],
        child: ScreenUtilInit(
          // The design was drawn at 402x860.
          designSize: const Size(AppDimens.designWidth, AppDimens.designHeight),
          minTextAdapt: true,
          builder: (context, _) => Builder(
            builder: (context) => MaterialApp(
              title: 'Tably',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.build(),
              locale: _resolveLocale(_languageCode(context)),
              localizationsDelegates: const [
                AppL10n.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppL10n.supportedLocales,
              // Tapping anywhere outside a text field dismisses the keyboard,
              // on every route and sheet.
              builder: (context, child) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: child,
              ),
              home: const RootScreen(),
            ),
          ),
        ),
      ),
    );
  }

  /// The saved profile owns the language once onboarding is done; before
  /// that, the language picked on the welcome screen applies immediately.
  String _languageCode(BuildContext context) {
    final onboarded = context.select<ProfileCubit, bool>((c) => c.state.hasOnboarded);
    final saved = context.select<ProfileCubit, String>((c) => c.state.profile.languageCode);
    final draft = context.select<OnboardingCubit, String>((c) => c.state.draft.languageCode);
    return onboarded ? saved : draft;
  }

  /// The language step offers more languages than the app currently ships
  /// translations for; anything unsupported falls back to French.
  Locale _resolveLocale(String languageCode) {
    final supported = AppL10n.supportedLocales.map((l) => l.languageCode);
    return Locale(supported.contains(languageCode) ? languageCode : 'fr');
  }
}
