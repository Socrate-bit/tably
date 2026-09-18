import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/primary_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/cubit/home_cubit.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../recipe/cubit/recipe_cubit.dart';
import '../../recipe/screen/recipe_screen.dart';
import '../../shopping/cubit/shopping_cubit.dart';
import '../../shopping/screen/shopping_screen.dart';
import '../cubit/plan_cubit.dart';
import '../widget/meal_card.dart';
import '../widget/plan_summary_cards.dart';

/// The menu tab: this week's dinners with cost and shopping progress on top.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return BlocListener<PlanCubit, PlanState>(
      listenWhen: (previous, current) => current.error != null && previous.error != current.error,
      listener: (context, state) {
        showErrorBanner(context, l10n.errorGeneratePlan);
        context.read<PlanCubit>().errorShown();
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          final profile = profileState.profile;
          return BlocBuilder<PlanCubit, PlanState>(
            builder: (context, planState) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(store: profile.store),
                    SizedBox(height: 22.h),
                    BlocBuilder<ShoppingCubit, ShoppingState>(
                      builder: (context, shoppingState) => Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: CostCard(
                              total: planState.totalCost,
                              budget: profile.budget,
                              country: profile.country,
                            ),
                          ),
                          SizedBox(width: 13.w),
                          Expanded(
                            child: ShoppingSummaryCard(
                              checked: shoppingState.checkedCount,
                              total: shoppingState.total,
                              onTap: () => _openShopping(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 22.h),
                    if (planState.status == PlanStatus.loading && planState.meals.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 60.h),
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.brand),
                        ),
                      )
                    else
                      for (final meal in planState.meals)
                        Padding(
                          padding: EdgeInsets.only(bottom: 18.h),
                          child: MealCard(
                            meal: meal,
                            servings: profile.household,
                            country: profile.country,
                            onTap: () => _openRecipe(context, meal.recipeId),
                          ),
                        ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: l10n.regeneratePlan,
                            gradient: true,
                            fontSize: 18,
                            verticalPadding: 18.h,
                            leading: _RegenerateGlyph(spinning: planState.generating),
                            onPressed: planState.generating
                                ? null
                                : () => context.read<PlanCubit>().generate(
                                      profile: profile,
                                      catalogue: context.read<RecipeCubit>().state.recipes,
                                      isRegeneration: true,
                                    ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        _PreferencesButton(
                          onTap: () => context.read<HomeCubit>().select(HomeTab.preferences),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openShopping(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ShoppingScreen()),
    );
  }

  void _openRecipe(BuildContext context, String recipeId) {
    context.read<RecipeCubit>().markViewed(recipeId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RecipeScreen(recipeId: recipeId)),
    );
  }
}

/// Wordmark plus the store chip.
class _Header extends StatelessWidget {
  const _Header({required this.store});

  final String store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🥗', style: TextStyle(fontSize: 26.sp, height: 1)),
            SizedBox(width: 10.w),
            Text(l10n.appName, style: AppTextStyles.wordmark),
          ],
        ),
        SizedBox(height: 14.h),
        StoreChip(store: store),
      ],
    );
  }
}

/// White circle holding the refresh arrow, which spins while regenerating.
class _RegenerateGlyph extends StatefulWidget {
  const _RegenerateGlyph({required this.spinning});

  final bool spinning;

  @override
  State<_RegenerateGlyph> createState() => _RegenerateGlyphState();
}

class _RegenerateGlyphState extends State<_RegenerateGlyph> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didUpdateWidget(_RegenerateGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.spinning ? _controller.repeat() : _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 30.r,
        height: 30.r,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        child: Text(
          '↻',
          style: TextStyle(fontSize: 15.sp, color: AppColors.brandDark, height: 1),
        ),
      ),
    );
  }
}

/// The round button next to "regenerate" that jumps to preferences.
class _PreferencesButton extends StatelessWidget {
  const _PreferencesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        width: 58.r,
        height: 58.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.brandSoftBorder),
        ),
        child: Text(
          '⚖',
          style: TextStyle(fontSize: 19.sp, color: AppColors.brandDark, height: 1),
        ),
      ),
    );
  }
}
