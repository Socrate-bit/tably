import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/model/weekday.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/cubit/onboarding_cubit.dart';
import '../../onboarding/widget/steps/simple_steps.dart';
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

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.prefsEyebrow, textAlign: TextAlign.center, style: AppTextStyles.eyebrow),
                SizedBox(height: 4.h),
                Text(
                  l10n.prefsTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.screenTitle,
                ),
                SizedBox(height: 26.h),

                PreferenceSectionHeader(title: l10n.prefsCountry),
                SizedBox(height: 10.h),
                _CountryRow(country: profile.country),
                SizedBox(height: 26.h),

                PreferenceSectionHeader(title: l10n.prefsStore),
                SizedBox(height: 10.h),
                _StoreRow(store: profile.store, onSelected: cubit.setStore),
                SizedBox(height: 26.h),

                PreferenceSectionHeader(
                  title: l10n.prefsHousehold,
                  subtitle: l10n.prefsHouseholdSub,
                ),
                SizedBox(height: 14.h),
                _HouseholdStepper(
                  count: profile.household,
                  onIncrement: cubit.incrementHousehold,
                  onDecrement: cubit.decrementHousehold,
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
                BudgetSlider(
                  budget: profile.budget,
                  minBudget: OnboardingCubit.minBudget,
                  maxBudget: OnboardingCubit.maxBudget,
                  country: profile.country,
                  onChanged: cubit.setBudget,
                  labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textQuaternary),
                ),
                SizedBox(height: 28.h),

                PreferenceSectionHeader(
                  title: l10n.prefsCravings,
                  subtitle: l10n.prefsChooseUpToThree,
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
                  subtitle: l10n.prefsChooseAllThatApply,
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
                  subtitle: l10n.prefsChooseAllThatApply,
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
          Text(country.flag, style: TextStyle(fontSize: 23.sp)),
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
          Text('⌄', style: TextStyle(color: AppColors.chevron, fontSize: 15.sp)),
        ],
      ),
    );
  }
}

/// Tapping opens a sheet listing every supported supermarket.
class _StoreRow extends StatelessWidget {
  const _StoreRow({required this.store, required this.onSelected});

  final String store;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 20.r,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      onTap: () => _pickStore(context),
      child: Row(
        children: [
          Container(
            width: 30.r,
            height: 30.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text('🛒', style: TextStyle(fontSize: 14.sp)),
          ),
          SizedBox(width: 14.w),
          Expanded(child: Text(store, style: AppTextStyles.listItemTitle)),
          Text('⌄', style: TextStyle(color: AppColors.chevron, fontSize: 15.sp)),
        ],
      ),
    );
  }

  Future<void> _pickStore(BuildContext context) async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 20.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in Stores.all)
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: SurfaceCard(
                    radius: 18.r,
                    borderColor: option == store ? AppColors.brand : AppColors.border,
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
                    onTap: () => Navigator.of(sheetContext).pop(option),
                    child: Text(option, style: AppTextStyles.listItemTitle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (selection != null) onSelected(selection);
  }
}

/// Compact +/− stepper for the household size.
class _HouseholdStepper extends StatelessWidget {
  const _HouseholdStepper({
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundButton(glyph: '−', enabled: count > 1, onTap: onDecrement),
            SizedBox(width: 30.w),
            SizedBox(
              width: 44.w,
              child: Text('$count', textAlign: TextAlign.center, style: AppTextStyles.numeralSmall),
            ),
            SizedBox(width: 30.w),
            _RoundButton(glyph: '+', enabled: true, onTap: onIncrement),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          l10n.peopleCount(count),
          style: AppTextStyles.caption.copyWith(color: AppColors.textQuaternary),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.glyph, required this.enabled, required this.onTap});

  final String glyph;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              Haptics.toggle();
              onTap();
            }
          : null,
      child: Container(
        width: 46.r,
        height: 46.r,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.fill, shape: BoxShape.circle),
        child: Text(
          glyph,
          style: TextStyle(
            fontSize: 22.sp,
            height: 1,
            color: enabled ? AppColors.inkStrong : AppColors.chevron,
          ),
        ),
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
