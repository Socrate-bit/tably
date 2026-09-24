import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../model/store.dart';
import '../theme/app_theme.dart';
import '../util/haptics.dart';

/// "Lidl ⌄" — the current store, tappable to compare prices across stores.
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
        padding: EdgeInsets.fromLTRB(16.w, 9.h, 14.w, 9.h),
        decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(22.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(store.displayName, style: AppTextStyles.storePill),
            SizedBox(width: 7.w),
            Text('⌄', style: AppTextStyles.storePill.copyWith(fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }
}
