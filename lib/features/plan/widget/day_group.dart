import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';

/// A day's meals under the dark day pill, which overlaps the first card.
class DayGroup extends StatelessWidget {
  const DayGroup({super.key, required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            // Room for the pill, which then overlaps the card by 11px.
            padding: EdgeInsets.only(top: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) SizedBox(height: 8.h),
                  child,
                ],
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(20.r)),
                child: Text(label, style: AppTextStyles.dayPill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
