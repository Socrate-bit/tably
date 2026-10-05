import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';

/// The dark day pill above a day's meals, centred on a hairline separator.
class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Container(height: 1, color: AppColors.border));

    return Padding(
      padding: EdgeInsets.only(top: 2.h, bottom: 3.h),
      child: Row(
        children: [
          line,
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
            decoration: BoxDecoration(color: AppColors.dayPill, borderRadius: BorderRadius.circular(20.r)),
            child: Text(label, style: AppTextStyles.dayPill),
          ),
          SizedBox(width: 8.w),
          line,
        ],
      ),
    );
  }
}
