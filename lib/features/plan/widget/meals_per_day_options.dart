import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/check_circle.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../preferences/model/user_profile.dart';

/// The two "N repas par jour" choices, each with what it covers.
class MealsPerDayOptions extends StatelessWidget {
  const MealsPerDayOptions({super.key, required this.selected, required this.onSelected, this.spacing});

  final int selected;
  final ValueChanged<int> onSelected;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var count = 1; count <= UserProfile.maxMealsPerDay; count++) ...[
          if (count > 1) SizedBox(height: spacing ?? 14.h),
          SurfaceCard(
            onTap: () => onSelected(count),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 19.h),
            borderColor: count == selected ? AppColors.brand : AppColors.border,
            borderWidth: count == selected ? 2.5 : 1,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.mealsPerDayOption(count), style: AppTextStyles.optionRow),
                      SizedBox(height: 2.h),
                      Text(l10n.mealsPerDayDetail(count), style: AppTextStyles.metaMuted.copyWith(color: AppColors.textQuaternary)),
                    ],
                  ),
                ),
                SizedBox(width: 14.w),
                CheckCircle(checked: count == selected, size: 26.r),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
