import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'features/account/cubit/auth_cubit.dart';
import 'features/home/screen/home_screen.dart';
import 'features/onboarding/screen/onboarding_screen.dart';
import 'features/plan/cubit/plan_cubit.dart';
import 'features/preferences/cubit/profile_cubit.dart';
import 'features/recipe/cubit/recipe_cubit.dart';
import 'features/shopping/cubit/shopping_cubit.dart';

/// Decides what the user sees: the native splash while auth resolves, onboarding for a
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
          if (!authState.isReady) return const SizedBox.shrink();

          return BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              if (profileState.isLoading) return const SizedBox.shrink();
              // Auth and profile resolved — drop the native splash.
              FlutterNativeSplash.remove();
              return profileState.hasOnboarded ? const HomeScreen() : const OnboardingScreen();
            },
          );
        },
      ),
    );
  }
}
