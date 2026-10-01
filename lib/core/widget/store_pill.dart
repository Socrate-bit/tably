import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../model/store.dart';
import '../theme/app_theme.dart';
import '../util/haptics.dart';
import 'line_icon.dart';

/// "🧭 Lidl ⌄": the current store, tappable to compare prices across stores.
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
        padding: EdgeInsets.fromLTRB(12.w, 9.h, 13.w, 9.h),
        decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(28.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22.r,
              height: 22.r,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
              child: LineIcon(LineGlyph.compass, size: 15.r, color: AppColors.surface, filled: true, strokeWidth: 1.2),
            ),
            SizedBox(width: 8.w),
            Text(store.displayName, style: AppTextStyles.storePill),
            SizedBox(width: 6.w),
            LineIcon(LineGlyph.chevronDown, size: 14.r, color: AppColors.brandDark, strokeWidth: 2.6),
          ],
        ),
      ),
    );
  }
}
