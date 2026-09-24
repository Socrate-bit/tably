import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/app_logo.dart';
import '../../../core/util/haptics.dart';
import '../../../l10n/app_localizations.dart';

/// The App Store rating prompt shown once onboarding's questions are answered.
class RatingModal extends StatelessWidget {
  const RatingModal({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return ColoredBox(
      color: AppColors.scrimModal,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(40.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 50.r,
                  offset: Offset(0, 20.h),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58.r,
                  height: 58.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: AppLogo(size: 34.r),
                ),
                SizedBox(height: 14.h),
                Text(
                  l10n.ratingTitle,
                  style: AppTextStyles.sheetTitle.copyWith(fontSize: 19.sp),
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.ratingSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.metaMuted.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 5; i++)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        child: GestureDetector(
                          onTap: () {
                            Haptics.confirm();
                            onDismiss();
                          },
                          child: Text(
                            '☆',
                            style: AppTextStyles.emojiIcon.copyWith(fontSize: 28.sp, color: AppColors.ratingStar),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 18.h),
                GestureDetector(
                  onTap: () {
                    Haptics.tap();
                    onDismiss();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: AppColors.track,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Text(
                      l10n.ratingNotNow,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.settingsRowTitle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
