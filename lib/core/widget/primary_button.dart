import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../util/haptics.dart';

/// The blue pill button used for every primary action.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailing,
    this.verticalPadding,
    this.fontSize,
    this.gradient = false,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Optional glyph after the label, e.g. the welcome screen's arrow.
  final String? trailing;
  final double? verticalPadding;
  final double? fontSize;

  /// The regenerate button uses a left-to-right brand gradient.
  final bool gradient;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final style = AppTextStyles.primaryButton.copyWith(
      fontSize: fontSize?.sp,
      color: AppColors.surface,
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled
            ? () {
                Haptics.confirm();
                onPressed!();
              }
            : null,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: verticalPadding ?? 20.h),
          decoration: BoxDecoration(
            color: gradient ? null : AppColors.brand,
            gradient: gradient
                ? const LinearGradient(
                    begin: Alignment(-0.9, -0.4),
                    end: Alignment(0.9, 0.4),
                    colors: [AppColors.brandLight, AppColors.brandDeep],
                  )
                : null,
            borderRadius: BorderRadius.circular(34.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.3),
                blurRadius: 22.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[leading!, SizedBox(width: 12.w)],
              Flexible(
                child: Text(label, style: style, textAlign: TextAlign.center),
              ),
              if (trailing != null) ...[
                SizedBox(width: 10.w),
                Text(trailing!, style: style),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// White pill button with a hairline border, used for secondary actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.radius});

  final String label;
  final VoidCallback? onPressed;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed == null
          ? null
          : () {
              Haptics.tap();
              onPressed!();
            },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(radius ?? 20.r),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.secondaryButton,
        ),
      ),
    );
  }
}
