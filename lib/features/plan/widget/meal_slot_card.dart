import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/recipe_photo.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../recipe/widget/craving_badge.dart';
import '../model/week_plan.dart';

/// One meal of the week: photo, optional slot name, title, badges and meta.
class MealSlotCard extends StatelessWidget {
  const MealSlotCard({
    super.key,
    required this.slot,
    required this.servings,
    required this.store,
    required this.country,
    required this.onTap,
  });

  /// Reheating leftovers takes a few minutes.
  static const leftoverTime = '5m';

  final PlanSlot slot;
  final int servings;
  final Store store;
  final Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final recipe = slot.recipe;
    final price = slot.isLeftover ? 0.0 : recipe.price * store.priceFactor;
    final divider = Text(' | ', style: AppTextStyles.rowMetaLarge.copyWith(color: AppColors.neutralBar));

    return SurfaceCard(
      onTap: onTap,
      radius: 24.r,
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          RecipePhoto(
            url: recipe.photoUrl,
            height: 104.r,
            width: 104.r,
            radius: 18.r,
            opacity: slot.isLeftover ? 0.8 : 1,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slot.showSlotLabel) ...[
                  Text(l10n.slotName(slot.slot).toUpperCase(), style: AppTextStyles.slotLabel),
                  SizedBox(height: 3.h),
                ],
                Text(recipe.title, style: AppTextStyles.mealTitle),
                Wrap(
                  spacing: 5.w,
                  children: [
                    CravingBadge(craving: recipe.craving),
                    if (slot.isLeftover) const _LeftoverBadge(),
                  ],
                ),
                SizedBox(height: 7.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text('🕐 ${slot.isLeftover ? leftoverTime : recipe.time}', style: AppTextStyles.rowMetaLarge),
                      divider,
                      Text('👤 $servings', style: AppTextStyles.rowMetaLarge),
                      divider,
                      Text(formatMoney(country, price), style: AppTextStyles.rowMetaLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "♻ Reste" next to the craving badge on reheated meals.
class _LeftoverBadge extends StatelessWidget {
  const _LeftoverBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(20.r)),
      child: Text(AppL10n.of(context).leftoverBadge, style: AppTextStyles.badgeSmall.copyWith(color: AppColors.brandDark)),
    );
  }
}
