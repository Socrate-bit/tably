import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ViewportOffset;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/weekday.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/app_logo.dart';
import '../../../core/widget/primary_button.dart';
import '../../../core/widget/store_pill.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/cubit/home_cubit.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../preferences/model/user_profile.dart';
import '../../recipe/cubit/catalogue_cubit.dart';
import '../../recipe/screen/recipe_screen.dart';
import '../../recipe/widget/quota_dialog.dart';
import '../../shopping/cubit/shopping_cubit.dart';
import '../../shopping/screen/shopping_screen.dart';
import '../cubit/plan_cubit.dart';
import '../model/week_plan.dart';
import '../widget/day_header.dart';
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
    // Hidden while the new week is being fetched.
    final outdated = catalogue.outdated && !plan.regenerating && !catalogue.isBuilding;
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
        // Without recipes the status below explains, but a spent quota
        // always gets its pop-up.
        BlocListener<CatalogueCubit, CatalogueState>(
          listenWhen: (previous, current) =>
              current.error != null &&
              previous.error != current.error &&
              (current.recipes.isNotEmpty || CatalogueCubit.reasonFor(current.error) == 'quota'),
          listener: (context, state) {
            showSearchError(context, state.error);
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sized off the width so it spans the same share of every phone,
                // shrinking only when a long store name needs the room.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AppWordmark(height: 64.w),
                  ),
                ),
                SizedBox(width: 8.w),
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
            // Keyed by the week so a regenerated plan slides in afresh. When the
            // preferences changed, the week dims under the regenerate prompt.
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedOpacity(
                  opacity: plan.regenerating ? 0.5 : (outdated ? 0.3 : 1),
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: outdated,
                    child: _WeekList(key: ValueKey(plan.settings.seed), week: week, profile: profile),
                  ),
                ),
                if (outdated) const Positioned(top: 0, left: 0, right: 0, child: _OutdatedPrompt()),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 36.h, bottom: 18.h),
              child: Center(
                child: RegenerateButton(
                  label: plan.regenerating ? l10n.regeneratingPlan : l10n.regeneratePlan,
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

/// The week as one reorderable list: each day's header, then its meals. Only
/// meals drag, by their dots; the headers stay put, so a dropped meal takes
/// the place it lands in and the meals in between shift along.
class _WeekList extends StatelessWidget {
  const _WeekList({super.key, required this.week, required this.profile});

  final WeekPlan week;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final items = <Object>[
      for (final (day, slots) in week.byDay) ...[day, ...slots],
    ];
    // Meals in display order, so each card knows its place in the week.
    final meals = items.whereType<PlanSlot>().toList();

    // The list reports where the dragged meal landed among headers and meals;
    // it takes the place of the meal it lands beside. Landing just under a
    // day's header means that day's first meal, just above it the day before's
    // last.
    void reorder(int from, int to) {
      final down = from < to;
      final target = switch (down ? items[to - 1] : items[to]) {
        final PlanSlot beside => meals.indexOf(beside),
        _ when down => meals.indexOf(items[to] as PlanSlot),
        _ => to == 0 ? 0 : meals.indexOf(items[to - 1] as PlanSlot),
      };
      final keys = [for (final meal in meals) meal.key];
      keys.insert(target, keys.removeAt(meals.indexOf(items[from] as PlanSlot)));
      context.read<PlanCubit>().reorder(keys);
    }

    // A fixed, non-scrolling viewport: the list lays out every item like the
    // column it replaces, while dragging near an edge scrolls the menu itself.
    return ShrinkWrappingViewport(
      offset: ViewportOffset.zero(),
      slivers: [
        SliverReorderableList(
          itemCount: items.length,
          onReorder: reorder,
          onReorderStart: (_) => Haptics.toggle(),
          onReorderEnd: (_) => Haptics.tap(),
          proxyDecorator: (child, _, animation) => ScaleTransition(
            scale: Tween<double>(begin: 1, end: 1.03).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
          itemBuilder: (context, i) => switch (items[i]) {
            final Weekday day => DayHeader(key: ValueKey(day), label: l10n.dayName(day).toUpperCase()),
            final slot as PlanSlot => Padding(
              key: ValueKey(slot.key),
              padding: EdgeInsets.only(bottom: 11.h),
              child: MealSlotCard(
                slot: slot,
                servings: profile.household,
                store: profile.store,
                country: profile.country,
                index: meals.indexOf(slot),
                dragIndex: i,
                onTap: () => RecipeScreen.open(context, recipeId: slot.recipe.id, slot: slot),
              ),
            ),
          },
        ),
      ],
    );
  }
}

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
            failed ? l10n.catalogueError(state.error) : l10n.catalogueBuilding,
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

/// Laid over the week when the preferences changed in a way the recipes
/// depend on: fetch a new week, or keep this one.
class _OutdatedPrompt extends StatelessWidget {
  const _OutdatedPrompt();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return SurfaceCard(
      shadow: true,
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.planOutdatedTitle, style: AppTextStyles.sheetTitle),
          SizedBox(height: 8.h),
          Text(l10n.planOutdatedBody, style: AppTextStyles.body),
          SizedBox(height: 18.h),
          PrimaryButton(label: l10n.planOutdatedRegenerate, onPressed: context.read<PlanCubit>().regenerate),
          SizedBox(height: 10.h),
          SecondaryButton(label: l10n.planOutdatedKeep, onPressed: context.read<CatalogueCubit>().keep),
        ],
      ),
    );
  }
}
