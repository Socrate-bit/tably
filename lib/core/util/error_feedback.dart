import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../util/haptics.dart';

/// Shows a failure to the user. Success is never announced — only errors get
/// UI feedback, per the app's conventions.
void showErrorBanner(BuildContext context, String message) {
  if (!context.mounted) return;
  Haptics.notify();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.secondaryButton.copyWith(color: AppColors.surface)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.r),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
    );
}
