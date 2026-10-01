import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/app_logo.dart';
import '../../../core/widget/primary_button.dart';
import '../../../core/widget/store_pill.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/cubit/home_cubit.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/model/user_profile.dart';
import '../../recipe/cubit/catalogue_cubit.dart';
import '../../recipe/screen/recipe_screen.dart';
import '../../shopping/cubit/shopping_cubit.dart';
import '../../shopping/screen/shopping_screen.dart';
import '../cubit/plan_cubit.dart';
import '../widget/day_group.dart';
import '../widget/meal_slot_card.dart';
import '../widget/plan_summary_cards.dart';
import '../widget/regenerate_button.dart';

/// The "Semaine" tab: the week's meals, with cost and shopping progress on top.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final profile = context.select<ProfileCubit, UserProfile>((c) => c.state.profile);
    final plan = context.watch<PlanCubit>().state;
    final catalogue = context.watch<CatalogueCubit>().state;
    final shopping = context.watch<ShoppingCubit>().state;
    final week = plan.week;
    final total = week.totalAt(profile.store);
    // Every slot in display order, so each card knows its place in the week.
    final order = [for (final (_, slots) in week.byDay) ...slots];
    void openStores() => context.read<HomeCubit>().open(HomeSub.stores);

    return MultiBlocListener(
      listeners: [
        BlocListener<PlanCubit, PlanState>(
          listenWhen: (previous, current) => current.error != null && previous.error != current.error,
          listener: (context, state) {
            showErrorBanner(context, l10n.errorGeneratePlan);
            context.read<PlanCubit>().errorShown();
          },
        ),
        // A rebuild after a preferences change failed; the old recipes stay.
        BlocListener<CatalogueCubit, CatalogueState>(
          listenWhen: (previous, current) =>
              current.error != null && previous.error != current.error && current.recipes.isNotEmpty,
          listener: (context, state) {
            showErrorBanner(context, catalogueErrorText(l10n, state.error));
            context.read<CatalogueCubit>().errorShown();
          },
        ),
      ],
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(15.w, 8.h, 15.w, AppDimens.tabBarInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Sized off the width so it spans the same share of every phone.
                AppWordmark(height: 64.w),
                const Spacer(),
                StorePill(store: profile.store, onTap: openStores),
              ],
            ),
            SizedBox(height: 16.h),
            // IntrinsicHeight bounds the row so both cards can stretch to the
            // same height; stretch alone would demand infinite height here.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CostCard(
                      total: total,
                      budget: profile.budget,
                      country: profile.country,
                      onTap: openStores,
                    ),
                  ),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: ShoppingSummaryCard(
                      checked: shopping.checkedCount,
                      total: shopping.total,
                      onTap: () => ShoppingScreen.open(context),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              l10n.planCounts(week.slotCount, week.recipeCount),
              style: AppTextStyles.planCounts,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            if (catalogue.recipes.isEmpty) _CatalogueStatus(state: catalogue),
            // Keyed by the week so a regenerated plan slides in afresh.
            AnimatedOpacity(
              opacity: plan.regenerating ? 0.5 : 1,
              duration: const Duration(milliseconds: 200),
              child: Column(
                key: ValueKey(plan.settings.seed),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (day, slots) in week.byDay)
                    DayGroup(
                      label: l10n.dayName(day).toUpperCase(),
                      children: [
                        for (final slot in slots)
                          MealSlotCard(
                            slot: slot,
                            servings: profile.household,
                            store: profile.store,
                            country: profile.country,
                            index: order.indexOf(slot),
                            onTap: () => RecipeScreen.open(context, recipeId: slot.recipe.id, slot: slot),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 34.h, bottom: 18.h),
              child: Center(
                child: RegenerateButton(
                  regenerating: plan.regenerating,
                  onPressed: context.read<PlanCubit>().regenerate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The message for a failed catalogue build.
String catalogueErrorText(AppL10n l10n, Object? error) => switch (CatalogueCubit.reasonFor(error)) {
      'quota' => l10n.errorCatalogueQuota,
      'no_match' => l10n.errorCatalogueEmpty,
      _ => l10n.errorCatalogue,
    };

/// Stands in for the week while there are no recipes yet: a spinner while
/// they are built, or the reason and a retry when the build failed.
class _CatalogueStatus extends StatelessWidget {
  const _CatalogueStatus({required this.state});

  final CatalogueState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final failed = state.status == CatalogueStatus.failed;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          if (!failed)
            SizedBox(
              width: 28.r,
              height: 28.r,
              child: const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brand),
            ),
          SizedBox(height: 16.h),
          Text(
            failed ? catalogueErrorText(l10n, state.error) : l10n.catalogueBuilding,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          if (failed) ...[
            SizedBox(height: 18.h),
            PrimaryButton(label: l10n.actionRetry, onPressed: context.read<CatalogueCubit>().retry),
          ],
        ],
      ),
    );
  }
}
