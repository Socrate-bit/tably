import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import 'circle_icon_button.dart';

/// Back arrow, title and optional subtitle or eyebrow, used by every pushed screen.
class SubScreenHeader extends StatelessWidget {
  const SubScreenHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final String? subtitle;

  /// All-caps line above the title ("CETTE SEMAINE").
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIconButton(glyph: '←', onPressed: onBack),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) Text(eyebrow!, style: AppTextStyles.eyebrow.copyWith(letterSpacing: 1.8.sp)),
              Text(title, style: AppTextStyles.subScreenTitle),
              if (subtitle != null) ...[
                SizedBox(height: 2.h),
                Text(subtitle!, style: AppTextStyles.subScreenSubtitle),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
