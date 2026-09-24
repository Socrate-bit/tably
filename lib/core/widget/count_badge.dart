import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// A small blue counter pinned to the top-right of [child]; hidden at zero.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: -4.r,
            right: -4.r,
            child: Container(
              constraints: BoxConstraints(minWidth: 20.r),
              height: 20.r,
              padding: EdgeInsets.symmetric(horizontal: 5.r),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(10.r)),
              child: Text('$count', style: AppTextStyles.badgeSmall.copyWith(color: AppColors.surface)),
            ),
          ),
      ],
    );
  }
}
