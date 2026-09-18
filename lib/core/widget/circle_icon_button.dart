import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../util/haptics.dart';

/// Round white button used for back arrows, the favourite heart and similar.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.glyph,
    required this.onPressed,
    this.size,
    this.fontSize,
    this.background = AppColors.surface,
    this.foreground = AppColors.ink,
    this.showBorder = true,
  });

  /// A single character or emoji — the design draws glyphs, not icon fonts.
  final String glyph;
  final VoidCallback? onPressed;
  final double? size;
  final double? fontSize;
  final Color background;
  final Color foreground;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 42.r;
    return GestureDetector(
      onTap: onPressed == null
          ? null
          : () {
              Haptics.tap();
              onPressed!();
            },
      child: Container(
        width: dimension,
        height: dimension,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: showBorder ? Border.all(color: AppColors.border) : null,
        ),
        child: Text(
          glyph,
          style: TextStyle(fontSize: fontSize?.sp ?? 17.sp, color: foreground, height: 1),
        ),
      ),
    );
  }
}
