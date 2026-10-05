import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/app_slider.dart';
import '../../../l10n/app_localizations.dart';
import '../model/user_profile.dart';

/// The longest a recipe may take: a readout over a 15–90 min slider, whose
/// end means no limit. Shared by the preferences and the search filters.
class CookTimeSlider extends StatelessWidget {
  const CookTimeSlider({super.key, required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final ends = AppTextStyles.meta.copyWith(color: AppColors.textQuaternary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          minutes < UserProfile.cookMinutesCeiling ? l10n.cookTimeMinutes('$minutes') : l10n.cookTimeNoLimit,
          style: AppTextStyles.priceRange,
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Text(l10n.cookTimeMinutes('${UserProfile.cookMinutesFloor}'), style: ends),
            SizedBox(width: 12.w),
            Expanded(
              child: AppSlider(
                value: minutes.toDouble(),
                min: UserProfile.cookMinutesFloor.toDouble(),
                max: UserProfile.cookMinutesCeiling.toDouble(),
                step: 5,
                onChanged: (value) => onChanged(value.round()),
              ),
            ),
            SizedBox(width: 12.w),
            Text(l10n.cookTimeMinutes('${UserProfile.cookMinutesCeiling}+'), style: ends),
          ],
        ),
      ],
    );
  }
}
