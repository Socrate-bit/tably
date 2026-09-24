import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import 'circle_icon_button.dart';

/// The design's full-height white sheet: back button, centred title, then [child].
class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  /// Slides a sheet up over the current screen.
  static Future<T?> show<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: AppColors.scrim,
        isScrollControlled: true,
        useSafeArea: true,
        builder: builder,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 30.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r), bottom: Radius.circular(46.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleIconButton(
                glyph: '←',
                size: 44.r,
                background: AppColors.surfaceMuted,
                showBorder: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 44.r),
                  child: Text(title, textAlign: TextAlign.center, style: AppTextStyles.sheetTitle),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: 6.h),
            Text(subtitle!, textAlign: TextAlign.center, style: AppTextStyles.metaMuted.copyWith(color: AppColors.textQuaternary)),
            SizedBox(height: 14.h),
          ] else
            SizedBox(height: 22.h),
          Expanded(child: child),
        ],
      ),
    );
  }
}
