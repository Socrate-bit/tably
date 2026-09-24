import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/theme/app_theme.dart';
import 'core/widget/app_logo.dart';
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
              return profileState.hasOnboarded ? const HomeScreen() : const OnboardingScreen();
            },
          );
        },
      ),
    );
  }
}

/// Brand splash shown while auth and the profile resolve.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(size: 40.r),
            SizedBox(height: 2.h),
            Text('Tably', style: AppTextStyles.wordmarkGenerating),
          ],
        ),
      ),
    );
  }
}
