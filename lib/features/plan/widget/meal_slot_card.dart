import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/model/store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/line_icon.dart';
import '../../../core/widget/recipe_photo.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../recipe/widget/craving_badge.dart';
import '../model/week_plan.dart';

/// One meal of the week: photo, optional slot name, title, badges, meta, and
/// a produce decoration above the open chevron.
class MealSlotCard extends StatelessWidget {
  const MealSlotCard({
    super.key,
    required this.slot,
    required this.servings,
    required this.store,
    required this.country,
    required this.index,
    required this.onTap,
  });

  /// Reheating leftovers takes a few minutes.
  static const leftoverTime = '5m';

  /// Corner decorations, cycled through the week so neighbours differ.
  static const _decorations = ['assets/decor/basil.png', 'assets/decor/pumpkin.png', 'assets/decor/lemon.png'];

  final PlanSlot slot;
  final int servings;
  final Store store;
  final Country country;

  /// The card's position in the week, which picks its decoration.
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final recipe = slot.recipe;
    final price = slot.isLeftover ? 0.0 : recipe.price * store.priceFactor;
    final divider = Text('  ·  ', style: AppTextStyles.rowMetaLarge.copyWith(color: AppColors.neutralBar));
    Widget icon(LineGlyph glyph) => Padding(
          padding: EdgeInsets.only(right: 5.w),
          child: LineIcon(glyph, size: 16.r, color: AppColors.textSecondary),
        );

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
                      icon(LineGlyph.clock),
                      Text(slot.isLeftover ? leftoverTime : recipe.time, style: AppTextStyles.rowMetaLarge),
                      divider,
                      icon(LineGlyph.user),
                      Text('$servings', style: AppTextStyles.rowMetaLarge),
                      divider,
                      Text(formatMoney(country, price), style: AppTextStyles.rowMetaLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          SizedBox(
            width: 52.r,
            height: 104.r,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(_decorations[index % _decorations.length], width: 52.r, filterQuality: FilterQuality.medium),
                const _OpenChevron(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The round "open" chevron at the end of the card; the whole card is the tap target.
class _OpenChevron extends StatelessWidget {
  const _OpenChevron();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.r,
      height: 36.r,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.brandSoft, shape: BoxShape.circle),
      child: LineIcon(LineGlyph.chevronRight, size: 18.r, color: AppColors.brand, strokeWidth: 2.4),
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
