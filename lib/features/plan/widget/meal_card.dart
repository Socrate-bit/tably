import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/recipe_photo.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../model/planned_meal.dart';

/// One dinner in the weekly plan: the day pill overlaps the top of the card.
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.servings,
    required this.country,
    required this.onTap,
  });

  final PlannedMeal meal;
  final int servings;
  final Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The pill sits 11px over the card below it.
        Transform.translate(
          offset: Offset(0, 11.h),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(l10n.dayName(meal.day).toUpperCase(), style: AppTextStyles.dayPill),
            ),
          ),
        ),
        SurfaceCard(
          radius: 24.r,
          padding: EdgeInsets.all(14.r),
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RecipePhoto(photoKey: meal.photoKey, height: 82.r, width: 82.r, radius: 16.r),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(meal.title, style: AppTextStyles.mealTitle),
                    SizedBox(height: 7.h),
                    _CravingBadge(cravingId: meal.cravingId),
                    SizedBox(height: 8.h),
                    _MetaRow(
                      time: meal.cookTime,
                      servings: servings,
                      price: formatMoney(country, meal.price),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Coloured pill naming the craving a meal satisfies.
class _CravingBadge extends StatelessWidget {
  const _CravingBadge({required this.cravingId});

  final String cravingId;

  @override
  Widget build(BuildContext context) {
    // "Quick meals" gets the purple treatment; everything else is pink.
    final isQuick = cravingId == Craving.quick.id;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: isQuick ? AppColors.badgeQuickBg : AppColors.badgeProteinBg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        AppL10n.of(context).cravingLabel(cravingId),
        style: AppTextStyles.badge.copyWith(
          color: isQuick ? AppColors.badgeQuickInk : AppColors.badgeProteinInk,
        ),
      ),
    );
  }
}

/// "🕐 25m | 👤 2 | €9.96"
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.time, required this.servings, required this.price});

  final String time;
  final int servings;
  final String price;

  @override
  Widget build(BuildContext context) {
    final divider = Text('|', style: AppTextStyles.meta.copyWith(color: AppColors.neutralBar));
    return Wrap(
      spacing: 9.w,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('🕐 $time', style: AppTextStyles.meta),
        divider,
        Text('👤 $servings', style: AppTextStyles.meta),
        divider,
        Text(price, style: AppTextStyles.meta),
      ],
    );
  }
}
