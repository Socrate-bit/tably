import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom sheet offering the ways to add a recipe.
class AddRecipeSheet extends StatelessWidget {
  const AddRecipeSheet({super.key});

  /// Presents the sheet over the current screen.
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: AppColors.scrim,
        isScrollControlled: true,
        builder: (_) => const AddRecipeSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tiles = <(String, String)>[
      ('🖼', l10n.addRecipePhoto),
      ('T', l10n.addRecipeText),
      ('🔗', l10n.addRecipeLink),
      ('✎', l10n.addRecipeScratch),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 34.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Haptics.tap();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 44.r,
                    height: 44.r,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Text('←', style: TextStyle(fontSize: 17.sp, color: AppColors.ink)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 44.w),
                    child: Text(
                      l10n.addRecipeTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sheetTitle,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 22.h),
            _WideOption(
              icon: '📱',
              title: l10n.addRecipeImportSocial,
              subtitle: l10n.addRecipeImportSocialSub,
            ),
            SizedBox(height: 13.h),
            _WideOption(
              icon: '📷',
              title: l10n.addRecipeScanFridge,
              subtitle: l10n.addRecipeScanFridgeSub,
              highlighted: true,
            ),
            SizedBox(height: 13.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 13.w,
              mainAxisSpacing: 13.h,
              childAspectRatio: 1.45,
              children: [
                for (final (icon, label) in tiles) _SmallOption(icon: icon, label: label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width option row; the highlighted variant is tinted blue.
class _WideOption extends StatelessWidget {
  const _WideOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.highlighted = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: Haptics.tap,
      child: Container(
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.brandSoft : AppColors.surface,
          border: Border.all(
            color: highlighted ? AppColors.brandSoftBorder : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          children: [
            Container(
              width: 46.r,
              height: 46.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: highlighted ? AppColors.surface : AppColors.brandSoft,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(icon, style: TextStyle(fontSize: 20.sp)),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTextStyles.listItemTitle),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.metaMuted.copyWith(
                      color: highlighted ? AppColors.brandSoftInk : AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Half-width tile in the 2x2 grid.
class _SmallOption extends StatelessWidget {
  const _SmallOption({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: Haptics.tap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                icon,
                style: TextStyle(fontSize: 19.sp, color: AppColors.brand),
              ),
            ),
            Text(label, style: AppTextStyles.optionGrid),
          ],
        ),
      ),
    );
  }
}
