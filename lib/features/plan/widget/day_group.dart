import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';

/// A day's meals under the dark day pill, centred on a hairline separator.
class DayGroup extends StatelessWidget {
  const DayGroup({super.key, required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Container(height: 1, color: AppColors.border));

    return Padding(
      padding: EdgeInsets.only(bottom: 13.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
          SizedBox(height: 3.h),
          for (final (i, child) in children.indexed) ...[
            if (i > 0) SizedBox(height: 11.h),
            child,
          ],
        ],
      ),
    );
  }
}
