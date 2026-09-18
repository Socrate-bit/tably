import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// Round tick used by the shopping list and the "mark as cooked" row.
class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key, required this.checked, this.size, this.uncheckedGlyphColor});

  final bool checked;
  final double? size;

  /// The cooked row shows a faint tick when unchecked; the shopping list hides it.
  final Color? uncheckedGlyphColor;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 30.r;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: dimension,
      height: dimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? AppColors.brand : Colors.transparent,
        border: checked ? null : Border.all(color: AppColors.neutralBar, width: 1.5),
      ),
      child: Text(
        '✓',
        style: TextStyle(
          fontSize: (dimension * 0.5),
          fontWeight: FontWeight.w800,
          height: 1,
          color: checked ? AppColors.surface : (uncheckedGlyphColor ?? Colors.transparent),
        ),
      ),
    );
  }
}
