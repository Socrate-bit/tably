import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/widget/loading_view.dart';
import 'features/account/cubit/auth_cubit.dart';
import 'features/chat/cubit/chat_cubit.dart';
import 'features/home/screen/home_screen.dart';
import 'features/onboarding/screen/onboarding_screen.dart';
import 'features/plan/cubit/plan_cubit.dart';
import 'features/preferences/cubit/profile_cubit.dart';
import 'features/recipe/cubit/catalogue_cubit.dart';
import 'features/recipe/cubit/recipe_cubit.dart';
import 'features/recipe/cubit/search_quota_cubit.dart';
import 'features/review/cubit/review_cubit.dart';
import 'features/shopping/cubit/shopping_cubit.dart';
import 'features/subscription/cubit/subscription_cubit.dart';

/// Decides what the user sees: a spinner while auth, the review flag and the profile resolve, onboarding for a
/// new user, or the app. Also binds every cubit to the signed-in uid.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.uid != current.uid,
      listener: (context, state) => _bind(context, state.uid),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // Waiting on the review flag keeps hidden features from flashing in.
          final reviewReady = context.select<ReviewCubit, bool>((c) => c.state.isReady);
          if (!authState.isReady || !reviewReady) return const LoadingView();
          // BlocListener skips the state it starts with, so a uid that was
          // already set on mount would never bind and the splash would hang.
          // Every bind is idempotent, so this is a no-op once bound.
          _bind(context, authState.uid);

          return BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              if (profileState.isLoading) return const LoadingView();
              return profileState.hasOnboarded ? const HomeScreen() : const OnboardingScreen();
            },
          );
        },
      ),
    );
  }

  /// One uid drives every stream in the app.
  static void _bind(BuildContext context, String? uid) {
    if (uid == null) return;
    context.read<ProfileCubit>().bind(uid);
    context.read<CatalogueCubit>().bind(uid);
    context.read<PlanCubit>().bind(uid);
    context.read<ShoppingCubit>().bind(uid);
    context.read<RecipeCubit>().bind(uid);
    context.read<SearchQuotaCubit>().bind(uid);
    context.read<ChatCubit>().bind(uid);
    // Ties the paywall to the same user, so purchases and the referral
    // grant follow them across launches.
    context.read<SubscriptionCubit>().identify(uid);
  }
}
