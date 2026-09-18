import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/account/cubit/auth_cubit.dart';
import 'features/home/screen/home_screen.dart';
import 'features/onboarding/screen/onboarding_screen.dart';
import 'features/plan/cubit/plan_cubit.dart';
import 'features/preferences/cubit/profile_cubit.dart';
import 'features/recipe/cubit/recipe_cubit.dart';
import 'features/shopping/cubit/shopping_cubit.dart';

/// Decides what the user sees: a splash while auth resolves, onboarding for a
/// new user, or the app. Also binds every cubit to the signed-in uid.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.uid != current.uid,
      listener: (context, state) {
        final uid = state.uid;
        if (uid == null) return;
        // One uid drives every stream in the app.
        context.read<ProfileCubit>().bind(uid);
        context.read<PlanCubit>().bind(uid);
        context.read<ShoppingCubit>().bind(uid);
        context.read<RecipeCubit>().bind(uid);
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (!authState.isReady) return const _Splash();

          return BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              if (profileState.isLoading) return const _Splash();
              return profileState.hasOnboarded ? const _PlannedHome() : const OnboardingScreen();
            },
          );
        },
      ),
    );
  }
}

/// The app shell, which generates a first plan if the user has none.
class _PlannedHome extends StatefulWidget {
  const _PlannedHome();

  @override
  State<_PlannedHome> createState() => _PlannedHomeState();
}

class _PlannedHomeState extends State<_PlannedHome> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<PlanCubit, PlanState>(
      // A ready-but-empty plan means onboarding just finished, or the week was
      // never built. Either way, build it once.
      listenWhen: (previous, current) =>
          current.status == PlanStatus.ready && current.meals.isEmpty && !current.generating,
      listener: (context, state) {
        final profile = context.read<ProfileCubit>().state.profile;
        context.read<PlanCubit>().generate(
              profile: profile,
              catalogue: context.read<RecipeCubit>().state.recipes,
            );
      },
      child: const HomeScreen(),
    );
  }
}

/// Brand splash shown while auth and the profile resolve.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🥗', style: TextStyle(fontSize: 34)),
            SizedBox(height: 4),
            Text(
              'Tably',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppColors.brand,
                letterSpacing: -1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
