import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// Thin rounded progress track used in onboarding and while generating a plan.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.animate = false, this.trackColor});

  /// 0.0–1.0.
  final double value;

  /// Animates width changes, as the generating screen does.
  final bool animate;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7.r),
      child: Container(
        height: 7.h,
        color: trackColor ?? AppColors.track,
        // Fractional sizing (not LayoutBuilder) so parents can measure intrinsics.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: animate ? const Duration(milliseconds: 600) : Duration.zero,
          curve: Curves.easeOut,
          builder: (context, fraction, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(7.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
