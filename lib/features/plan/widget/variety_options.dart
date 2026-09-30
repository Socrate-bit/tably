import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../preferences/model/user_profile.dart';

/// Up to three variety levels, each showing how many recipes it means cooking
/// for [profile]'s week; the other meals are leftovers.
class VarietyOptions extends StatelessWidget {
  const VarietyOptions({super.key, required this.profile, required this.onSelected, this.spacing});

  final UserProfile profile;
  final ValueChanged<Variety> onSelected;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, MapEntry(key: variety, value: count)) in profile.varietyRecipes.entries.indexed) ...[
          if (index > 0) SizedBox(height: spacing ?? 14.h),
          _VarietyCard(
            variety: variety,
            count: count,
            mealCount: profile.mealCount,
            // A merged level is checked through the count it shares.
            checked: count == profile.recipesToCook,
            onTap: () => onSelected(variety),
          ),
        ],
      ],
    );
  }
}

/// One variety level: emoji, name, what it means for the week, and a big
/// recipe count on the right.
class _VarietyCard extends StatelessWidget {
  const _VarietyCard({
    required this.variety,
    required this.count,
    required this.mealCount,
    required this.checked,
    required this.onTap,
  });

  final Variety variety;
  final int count;
  final int mealCount;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return SurfaceCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      borderColor: checked ? AppColors.brand : AppColors.border,
      borderWidth: checked ? 2.5 : 1,
      child: Row(
        children: [
          Text(variety.icon, style: AppTextStyles.emojiIcon.copyWith(fontSize: 26.sp)),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.varietyName(variety), style: AppTextStyles.optionRow),
                SizedBox(height: 2.h),
                Text(
                  count == mealCount ? l10n.diversityAllDifferent : l10n.diversityDetailReuse(count, mealCount),
                  style: AppTextStyles.metaMuted.copyWith(color: AppColors.textQuaternary),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '$count',
            style: AppTextStyles.optionRow.copyWith(
              fontSize: 26.sp,
              color: checked ? AppColors.brand : AppColors.textQuaternary,
            ),
          ),
        ],
      ),
    );
  }
}
