import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/line_icon.dart';
import '../cubit/search_quota_cubit.dart';
import 'quota_dialog.dart';

/// "🔍 27/30": the recipe searches left today, beside the store pill. Red
/// once they are spent; tapping explains the limit and when it resets.
class SearchQuotaBadge extends StatelessWidget {
  const SearchQuotaBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final (:remaining, :limit) = context.select<SearchQuotaCubit, ({int remaining, int limit})>(
      (c) => (remaining: c.state.remaining, limit: c.state.limit),
    );
    final color = remaining == 0 ? AppColors.danger : AppColors.brandDark;

    return GestureDetector(
      onTap: () {
        Haptics.tap();
        context.read<SearchQuotaCubit>().opened();
        QuotaDialog.show(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(28.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LineIcon(LineGlyph.search, size: 15.r, color: color, strokeWidth: 2.4),
            SizedBox(width: 4.w),
            Text('$remaining/$limit', style: AppTextStyles.storePill.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
