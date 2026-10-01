import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// Rounded progress track with the brand gradient fill (onboarding, plan
/// generation, and the week's cost and shopping cards).
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.animate = false, this.trackColor, this.height});

  /// 0.0–1.0.
  final double value;

  /// Animates width changes, as the generating screen does.
  final bool animate;
  final Color? trackColor;

  /// Defaults to 7.h.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final barHeight = height ?? 7.h;
    final radius = BorderRadius.circular(barHeight / 2);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: barHeight,
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
                gradient: const LinearGradient(colors: [AppColors.brandLight, AppColors.brand]),
                borderRadius: radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
