import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/line_icon.dart';
import '../../../core/widget/progress_bar.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';

/// The cost card: spend so far against the weekly budget, and what that
/// saves unless [showSavings] is false. Tapping it opens the store price
/// comparison, unless [onTap] is null.
class CostCard extends StatelessWidget {
  const CostCard({
    super.key,
    required this.total,
    required this.budget,
    required this.country,
    required this.onTap,
    this.showSavings = true,
  });

  final double total;
  final double budget;
  final Country country;
  final VoidCallback? onTap;
  final bool showSavings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final ratio = budget <= 0 ? 0.0 : (total / budget).clamp(0.0, 1.0);

    return SurfaceCard(
      padding: EdgeInsets.all(16.r),
      onTap: onTap,
      child: _CornerIcon(
        glyph: LineGlyph.coins,
        background: AppColors.brandSoft,
        size: 40.r,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _clearOf(40.r, Text(l10n.estimatedCost, style: AppTextStyles.cardLabel)),
            SizedBox(height: 10.h),
            _OneLine(
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(formatMoney(country, total), style: AppTextStyles.amountLarge),
                  Text(' / ${formatMoney(country, budget)}', style: AppTextStyles.amountMuted),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            ProgressBar(value: ratio, height: 8.h, trackColor: AppColors.track),
            if (showSavings) ...[
              SizedBox(height: 10.h),
              _OneLine(
                Text(
                  l10n.budgetSavings(formatMoney(country, (budget - total).clamp(0, budget), decimals: 0)),
                  style: AppTextStyles.savings,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The tinted shopping-list card that opens the full list.
class ShoppingSummaryCard extends StatelessWidget {
  const ShoppingSummaryCard({super.key, required this.checked, required this.total, required this.onTap});

  final int checked;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final ratio = total == 0 ? 0.0 : checked / total;

    return SurfaceCard(
      color: AppColors.info,
      borderColor: null,
      padding: EdgeInsets.all(16.r),
      onTap: onTap,
      child: _CornerIcon(
        glyph: LineGlyph.cart,
        background: AppColors.brandChip,
        size: 40.r,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _clearOf(40.r, Text(l10n.tapToView, style: AppTextStyles.cardLabelInfo)),
            SizedBox(height: 10.h),
            _clearOf(
              40.r,
              Text(l10n.shoppingList, style: AppTextStyles.sheetTitle.copyWith(fontSize: 16.sp, letterSpacing: -0.6)),
            ),
            SizedBox(height: 4.h),
            _OneLine(
              Text(
                l10n.shoppingBoughtCount(checked, total),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.inkBody,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            ProgressBar(value: ratio, height: 8.h, trackColor: AppColors.infoTrack),
          ],
        ),
      ),
    );
  }
}

/// Keeps a card's top lines left of its [_CornerIcon], shrinking them if needed.
Widget _clearOf(double iconSize, Widget text) => Padding(
  padding: EdgeInsets.only(right: iconSize + 4.w),
  child: _OneLine(text),
);

/// Scales [text] down to fit on one line. The [IntrinsicHeight] row measures
/// it at its narrow width, where wrapped lines left empty space at the bottom
/// of the cards, so its height is pinned to one line's.
class _OneLine extends StatelessWidget {
  const _OneLine(this.text);

  final Widget text;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    maxLines: 1,
    softWrap: false,
    child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: text),
  );
}

/// Pins a round icon badge to the card's top-right corner, over [child].
class _CornerIcon extends StatelessWidget {
  const _CornerIcon({required this.glyph, required this.background, required this.size, required this.child});

  final LineGlyph glyph;
  final Color background;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -2.r,
          right: -2.r,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: LineIcon(glyph, size: size * 0.55, color: AppColors.brand, strokeWidth: 2.1),
          ),
        ),
      ],
    );
  }
}
