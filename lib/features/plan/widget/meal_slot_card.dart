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

/// One meal of the week: photo, optional slot name, title, badges, meta and
/// an open chevron, with a produce decoration bleeding off the top-right.
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
    Widget icon(LineGlyph glyph, {bool filled = false}) => Padding(
          padding: EdgeInsets.only(right: 5.w),
          child: LineIcon(glyph, size: 18.r, color: AppColors.textSecondary, filled: filled),
        );
    final photoSize = 120.r;

    return SurfaceCard(
      onTap: onTap,
      radius: 24.r,
      clip: true,
      child: Stack(
        children: [
          // Painted first so text stays on top; the card clips its right edge.
          Positioned(
            top: 8.r,
            right: -14.r,
            child: Image.asset(
              _decorations[index % _decorations.length],
              width: 76.r,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(11.r),
            child: Row(
              children: [
                RecipePhoto(
                  url: recipe.photoUrl,
                  height: photoSize,
                  width: photoSize,
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
                            SizedBox(width: 14.w),
                            icon(LineGlyph.user, filled: true),
                            Text('$servings', style: AppTextStyles.rowMetaLarge),
                            divider,
                            Text(formatMoney(country, price), style: AppTextStyles.rowMetaLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Sits in the lower half, under the decoration.
                SizedBox(
                  height: photoSize,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 6.r),
                    child: const Align(alignment: Alignment.bottomCenter, child: _OpenChevron()),
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

/// The round "open" chevron at the end of the card; the whole card is the tap target.
class _OpenChevron extends StatelessWidget {
  const _OpenChevron();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.r,
      height: 42.r,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.brandSoft, shape: BoxShape.circle),
      child: LineIcon(LineGlyph.chevronRight, size: 24.r, color: AppColors.brand, strokeWidth: 2.4),
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
