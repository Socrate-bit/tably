import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/primary_button.dart';
import '../../../core/widget/recipe_photo.dart';
import '../../../core/widget/sub_screen_header.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../../core/widget/app_slider.dart';
import '../cubit/recipe_browse_cubit.dart';
import '../model/recipe.dart';

/// "Filtres": cravings, cuisine, protein, diets, allergies, appliances and
/// price per portion.
class FiltersScreen extends StatelessWidget {
  const FiltersScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FiltersScreen()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final cubit = context.read<RecipeBrowseCubit>();
    final state = context.watch<RecipeBrowseCubit>().state;
    final country = context.select<ProfileCubit, Country>((c) => c.state.profile.country);

    Widget grid(List<Widget> children) => GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.9,
          children: children,
        );

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 26.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SubScreenHeader(
                title: l10n.filtersTitle,
                onBack: () => Navigator.of(context).pop(),
                trailing: GestureDetector(
                  onTap: () {
                    Haptics.tap();
                    cubit.resetFilters();
                  },
                  child: Text(l10n.filtersReset, style: AppTextStyles.link.copyWith(fontSize: 15.sp)),
                ),
              ),
              SizedBox(height: 22.h),
              Text(l10n.filtersCravings, style: AppTextStyles.filterSection),
              SizedBox(height: 12.h),
              grid([
                for (final craving in Craving.values)
                  _FilterChip(
                    icon: craving.icon,
                    label: l10n.cravingLabel(craving),
                    selected: state.cravings.contains(craving),
                    onTap: () => cubit.toggleCraving(craving),
                  ),
              ]),
              SizedBox(height: 28.h),
              Text(l10n.filtersCuisine, style: AppTextStyles.filterSection),
              SizedBox(height: 12.h),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.98,
                children: [
                  for (final cuisine in Cuisine.values)
                    _CuisineCard(
                      cuisine: cuisine,
                      selected: state.cuisines.contains(cuisine),
                      onTap: () => cubit.toggleCuisine(cuisine),
                    ),
                ],
              ),
              SizedBox(height: 28.h),
              Text(l10n.filtersProtein, style: AppTextStyles.filterSection),
              SizedBox(height: 2.h),
              Text(l10n.filtersProteinSub, style: AppTextStyles.caption.copyWith(fontSize: 14.5.sp)),
              SizedBox(height: 12.h),
              grid([
                for (final protein in RecipeProtein.values)
                  _FilterChip(
                    icon: protein.icon,
                    label: l10n.proteinName(protein),
                    selected: state.proteins.contains(protein),
                    onTap: () => cubit.toggleProtein(protein),
                  ),
              ]),
              // Diets, allergies and appliances: the profile's by default,
              // and changing them here only affects the search.
              for (final (title, chips) in [
                (
                  l10n.prefsDiet,
                  [
                    for (final diet in Diet.values)
                      _FilterChip(
                        icon: diet.icon,
                        label: l10n.optionLabel(diet.id),
                        selected: state.constraints.diets.contains(diet),
                        onTap: () => cubit.toggleDiet(diet),
                      ),
                  ],
                ),
                (
                  l10n.prefsAllergens,
                  [
                    for (final allergy in Allergy.values)
                      _FilterChip(
                        icon: allergy.icon,
                        label: l10n.optionLabel(allergy.id),
                        selected: state.constraints.allergies.contains(allergy),
                        onTap: () => cubit.toggleAllergy(allergy),
                      ),
                  ],
                ),
                (
                  l10n.prefsAppliances,
                  [
                    for (final appliance in Appliance.values)
                      _FilterChip(
                        icon: appliance.icon,
                        label: l10n.optionLabel(appliance.id),
                        selected: state.constraints.appliances.contains(appliance),
                        onTap: () => cubit.toggleAppliance(appliance),
                      ),
                  ],
                ),
              ]) ...[
                SizedBox(height: 28.h),
                Text(title, style: AppTextStyles.filterSection),
                SizedBox(height: 2.h),
                Text(l10n.filtersFromPreferences, style: AppTextStyles.caption.copyWith(fontSize: 14.5.sp)),
                SizedBox(height: 12.h),
                grid(chips),
              ],
              SizedBox(height: 28.h),
              Text(l10n.filtersPrice, style: AppTextStyles.filterSection),
              SizedBox(height: 8.h),
              Text(
                l10n.filtersPriceRange(
                  formatMoney(country, RecipeBrowseCubit.priceFloor, decimals: 0),
                  _price(country, state.maxPrice),
                ),
                style: AppTextStyles.priceRange,
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Text(formatMoney(country, RecipeBrowseCubit.priceFloor, decimals: 0), style: AppTextStyles.meta.copyWith(color: AppColors.textQuaternary)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppSlider(
                      value: state.maxPrice,
                      min: RecipeBrowseCubit.priceFloor,
                      max: RecipeBrowseCubit.priceCeiling,
                      step: 0.1,
                      onChanged: cubit.setMaxPrice,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(formatMoney(country, RecipeBrowseCubit.priceCeiling, decimals: 0), style: AppTextStyles.meta.copyWith(color: AppColors.textQuaternary)),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                state.hasPriceLimit ? l10n.filtersPriceUpTo(formatMoney(country, state.maxPrice)) : l10n.filtersPriceAll,
                style: AppTextStyles.subScreenSubtitle,
              ),
              SizedBox(height: 28.h),
              PrimaryButton(
                label: l10n.filtersApply,
                fontSize: 17,
                verticalPadding: 18.h,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "€7.5" rather than "€7.50", as the design trims a trailing ".00" / "0".
  static String _price(Country country, double value) {
    final text = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '');
    return '${country.currencySymbol}$text';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.icon, required this.label, required this.selected, required this.onTap});

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      radius: 20.r,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      color: selected ? AppColors.brandSoft : AppColors.surface,
      borderColor: selected ? AppColors.brand : AppColors.border,
      borderWidth: selected ? 2.5 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: AppTextStyles.emojiIcon.copyWith(fontSize: 26.sp)),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTextStyles.filterChip.copyWith(color: selected ? AppColors.brandDark : AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _CuisineCard extends StatelessWidget {
  const _CuisineCard({required this.cuisine, required this.selected, required this.onTap});

  final Cuisine cuisine;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return SurfaceCard(
      onTap: onTap,
      radius: 20.r,
      clip: true,
      borderColor: selected ? AppColors.brand : AppColors.border,
      borderWidth: selected ? 2.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: RecipePhoto(photoKey: cuisine.photoKey, height: double.infinity, radius: 0)),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.cuisineName(cuisine), style: AppTextStyles.recipeRowTitle, maxLines: 1),
                SizedBox(height: 3.h),
                Text(l10n.cuisineDescription(cuisine), style: AppTextStyles.metaSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
