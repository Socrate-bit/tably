import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../util/haptics.dart';

/// The white, hairline-bordered card the whole app is built from.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.borderWidth = 1,
    this.onTap,
    this.clip = false,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final Color color;

  /// Pass null for a borderless tinted card.
  final Color? borderColor;

  /// Selected cards use the design's 2.5px brand outline.
  final double borderWidth;
  final VoidCallback? onTap;

  /// Clips children to the rounded corners (used by list and image cards).
  final bool clip;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius ?? 22.r);
    final card = Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: borderColor == null ? null : Border.all(color: borderColor!, width: borderWidth),
        boxShadow: shadow
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2.r, offset: Offset(0, 1.h))]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap!();
      },
      child: card,
    );
  }
}
