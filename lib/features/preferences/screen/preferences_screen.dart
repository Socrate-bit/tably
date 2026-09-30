import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/model/weekday.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/app_slider.dart';
import '../../../core/widget/household_stepper.dart';
import '../../../core/widget/store_pill.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/cubit/home_cubit.dart';
import '../../onboarding/cubit/onboarding_cubit.dart';
import '../../plan/widget/meals_per_day_options.dart';
import '../cubit/profile_cubit.dart';
import '../widget/preference_grid.dart';

/// The preferences tab. Every control writes straight through to the profile,
/// so changes are live everywhere else in the app.
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) => current.error != null && previous.error != current.error,
      listener: (context, state) {
        showErrorBanner(context, l10n.errorSavePreferences);
        context.read<ProfileCubit>().errorShown();
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final cubit = context.read<ProfileCubit>();
          final profile = state.profile;
          void openStores() => context.read<HomeCubit>().open(HomeSub.stores);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, AppDimens.tabBarInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l10n.prefsTitle, style: AppTextStyles.tabTitle)),
                    StorePill(store: profile.store, onTap: openStores),
                  ],
                ),
                SizedBox(height: 16.h),

                PreferenceSectionHeader(title: l10n.prefsCountry),
                SizedBox(height: 10.h),
                _CountryRow(country: profile.country),
                SizedBox(height: 26.h),

                PreferenceSectionHeader(title: l10n.prefsStore),
                SizedBox(height: 10.h),
                _StoreRow(store: profile.store, onTap: openStores),
                SizedBox(height: 26.h),

                PreferenceSectionHeader(
                  title: l10n.prefsHousehold,
                  subtitle: l10n.prefsHouseholdSub,
                ),
                SizedBox(height: 14.h),
                HouseholdStepper(
                  compact: true,
                  count: profile.household,
                  onIncrement: cubit.incrementHousehold,
                  onDecrement: cubit.decrementHousehold,
                ),
                SizedBox(height: 28.h),

                PreferenceSectionHeader(
                  title: l10n.prefsMealsPerDay,
                  subtitle: l10n.prefsMealsPerDaySub,
                ),
                SizedBox(height: 14.h),
                MealsPerDayOptions(
                  selected: profile.mealsPerDay,
                  spacing: 10.h,
                  onSelected: cubit.setMealsPerDay,
                ),
                SizedBox(height: 28.h),

                PreferenceSectionHeader(
                  title: l10n.prefsCookingDays,
                  subtitle: l10n.prefsCookingDaysSub,
                ),
                SizedBox(height: 14.h),
                _DayChips(selected: profile.days, onToggle: cubit.toggleDay),
                SizedBox(height: 28.h),

                PreferenceSectionHeader(title: l10n.prefsBudget),
                SizedBox(height: 8.h),
                _BudgetReadout(
                  budget: profile.budget,
                  country: profile.country,
                  days: profile.daysCount,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Expanded(
                      child: AppSlider(
                        value: profile.budget,
                        min: OnboardingCubit.minBudget,
                        max: OnboardingCubit.maxBudget,
                        step: 0.5,
                        onChanged: cubit.setBudget,
                      ),
                    ),
                    SizedBox(width: 13.w),
                    Text(
                      formatMoney(profile.country, OnboardingCubit.maxBudget),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textQuaternary),
                    ),
                  ],
                ),
                SizedBox(height: 28.h),

                PreferenceSectionHeader(
                  title: l10n.prefsCravings,
                  subtitle: l10n.chooseUpToThree,
                ),
                SizedBox(height: 14.h),
                PreferenceGrid<Craving>(
                  values: Craving.values,
                  idOf: (c) => c.id,
                  iconOf: (c) => c.icon,
                  selected: profile.cravings,
                  onToggle: cubit.toggleCraving,
                ),
                SizedBox(height: 28.h),

                PreferenceSectionHeader(
                  title: l10n.prefsDiet,
                  subtitle: l10n.chooseAllThatApply,
                ),
                SizedBox(height: 14.h),
                PreferenceGrid<Diet>(
                  values: Diet.values,
                  idOf: (d) => d.id,
                  iconOf: (d) => d.icon,
                  selected: profile.diets,
                  onToggle: cubit.toggleDiet,
                ),
                SizedBox(height: 28.h),

                PreferenceSectionHeader(
                  title: l10n.prefsAllergens,
                  subtitle: l10n.chooseAllThatApply,
                ),
                SizedBox(height: 14.h),
                PreferenceGrid<Allergy>(
                  values: Allergy.values,
                  idOf: (a) => a.id,
                  iconOf: (a) => a.icon,
                  selected: profile.allergies,
                  onToggle: cubit.toggleAllergy,
                ),
                SizedBox(height: 28.h),

                PreferenceSectionHeader(
                  title: l10n.prefsProteins,
                  subtitle: l10n.prefsProteinsSub,
                ),
                SizedBox(height: 14.h),
                PreferenceGrid<Protein>(
                  values: Protein.values,
                  idOf: (p) => p.id,
                  iconOf: (p) => p.icon,
                  selected: profile.proteins,
                  onToggle: cubit.toggleProtein,
                ),
                SizedBox(height: 28.h),

                PreferenceSectionHeader(
                  title: l10n.prefsAppliances,
                  subtitle: l10n.prefsAppliancesSub,
                ),
                SizedBox(height: 14.h),
                PreferenceGrid<Appliance>(
                  values: Appliance.values,
                  idOf: (a) => a.id,
                  iconOf: (a) => a.icon,
                  selected: profile.appliances,
                  onToggle: cubit.toggleAppliance,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Flag, name and currency chip.
class _CountryRow extends StatelessWidget {
  const _CountryRow({required this.country});

  final Country country;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return SurfaceCard(
      radius: 20.r,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      child: Row(
        children: [
          Text(country.flag, style: AppTextStyles.emojiIcon.copyWith(fontSize: 23.sp)),
          SizedBox(width: 14.w),
          Expanded(child: Text(l10n.optionLabel(country.id), style: AppTextStyles.listItemTitle)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.trackDark),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '${country.currencySymbol} ${country.currencyCode}',
              style: AppTextStyles.chip.copyWith(color: AppColors.textSecondary),
            ),
          ),
          SizedBox(width: 8.w),
          Text('⌄', style: AppTextStyles.emojiIcon.copyWith(color: AppColors.chevron, fontSize: 15.sp)),
        ],
      ),
    );
  }
}

/// The current store; tapping opens the price comparison to switch.
class _StoreRow extends StatelessWidget {
  const _StoreRow({required this.store, required this.onTap});

  final Store store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 20.r,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 30.r,
            height: 30.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(8.r)),
            child: Text('🛒', style: AppTextStyles.emojiIcon.copyWith(fontSize: 14.sp)),
          ),
          SizedBox(width: 14.w),
          Expanded(child: Text(store.displayName, style: AppTextStyles.listItemTitle)),
          Text('⌄', style: AppTextStyles.emojiIcon.copyWith(color: AppColors.chevron, fontSize: 15.sp)),
        ],
      ),
    );
  }
}

/// Seven single-letter day toggles.
class _DayChips extends StatelessWidget {
  const _DayChips({required this.selected, required this.onToggle});

  final Set<Weekday> selected;
  final ValueChanged<Weekday> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Row(
      children: [
        for (final (index, day) in Weekday.values.indexed) ...[
          Expanded(
            child: GestureDetector(
              onTap: () {
                Haptics.toggle();
                onToggle(day);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                // Painted over the label so a thicker selected border never reflows it.
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: selected.contains(day) ? AppColors.brand : AppColors.border,
                    width: selected.contains(day) ? 2.5 : 1,
                  ),
                ),
                child: Text(
                  l10n.dayShort(day),
                  style: AppTextStyles.dayChip.copyWith(
                    color: selected.contains(day) ? AppColors.ink : AppColors.textDisabled,
                  ),
                ),
              ),
            ),
          ),
          if (index < Weekday.values.length - 1) SizedBox(width: 7.w),
        ],
      ],
    );
  }
}

/// "€60.00 pour 7 jours"
class _BudgetReadout extends StatelessWidget {
  const _BudgetReadout({required this.budget, required this.country, required this.days});

  final double budget;
  final Country country;
  final int days;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          formatMoney(country, budget),
          style: AppTextStyles.amountLarge.copyWith(fontSize: 30.sp, letterSpacing: -1.sp),
        ),
        Flexible(
          child: Text(
            AppL10n.of(context).prefsBudgetForDays(days),
            style: AppTextStyles.metaMuted.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
