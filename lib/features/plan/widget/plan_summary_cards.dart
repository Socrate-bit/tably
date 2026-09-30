import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';

/// The cost card: spend so far against the weekly budget. Tapping it opens
/// the store price comparison.
class CostCard extends StatelessWidget {
  const CostCard({super.key, required this.total, required this.budget, required this.country, required this.onTap});

  final double total;
  final double budget;
  final Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final ratio = budget <= 0 ? 0.0 : (total / budget).clamp(0.0, 1.0);

    return SurfaceCard(
      padding: EdgeInsets.all(16.r),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.estimatedCost, style: AppTextStyles.cardLabel),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(formatMoney(country, total), style: AppTextStyles.amountLarge),
                Text(' / ${formatMoney(country, budget)}', style: AppTextStyles.amountMuted),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(7.r),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7.h,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.brand),
            ),
          ),
          SizedBox(height: 9.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.budgetSavings(formatMoney(country, (budget - total).clamp(0, budget), decimals: 0)),
              style: AppTextStyles.savings,
            ),
          ),
        ],
      ),
    );
  }
}

/// The tinted shopping-list card that opens the full list.
class ShoppingSummaryCard extends StatelessWidget {
  const ShoppingSummaryCard({
    super.key,
    required this.checked,
    required this.total,
    required this.onTap,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.tapToView, style: AppTextStyles.cardLabelInfo),
          SizedBox(height: 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.shoppingList,
              style: AppTextStyles.sheetTitle.copyWith(fontSize: 18.sp, letterSpacing: -0.6),
            ),
          ),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.shoppingBoughtCount(checked, total),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.inkBody,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(7.r),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7.h,
              backgroundColor: AppColors.infoTrack,
              valueColor: const AlwaysStoppedAnimation(AppColors.brand),
            ),
          ),
        ],
      ),
    );
  }
}
