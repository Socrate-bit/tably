import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../model/store.dart';
import '../theme/app_theme.dart';
import '../util/haptics.dart';
import 'line_icon.dart';

/// "🧭 Lidl ⌄" — the current store, tappable to compare prices across stores.
class StorePill extends StatelessWidget {
  const StorePill({super.key, required this.store, required this.onTap});

  final Store store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 8.h),
        decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(28.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
              child: LineIcon(LineGlyph.compass, size: 18.r, color: AppColors.surface, strokeWidth: 2.1),
            ),
            SizedBox(width: 9.w),
            Text(store.displayName, style: AppTextStyles.storePill),
            SizedBox(width: 7.w),
            Text('⌄', style: AppTextStyles.storePill.copyWith(fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }
}
