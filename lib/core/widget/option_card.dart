import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/onboarding/model/onboarding_step.dart';
import '../theme/app_theme.dart';
import '../util/haptics.dart';

/// A selectable option, shared by onboarding and the preferences screen.
/// Selection is shown by a 2.5px brand border, exactly as in the design.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.layout = OptionLayout.grid,
    this.icon,
    this.chip,
    this.serif = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final OptionLayout layout;
  final String? icon;

  /// Trailing pill, used for currency codes.
  final String? chip;
  final bool serif;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        padding: _padding,
        constraints: layout == OptionLayout.grid ? BoxConstraints(minHeight: 112.h) : null,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.03 : 0.02),
              blurRadius: selected ? 3.r : 2.r,
              offset: Offset(0, 1.h),
            ),
          ],
        ),
        child: switch (layout) {
          OptionLayout.rows => _rowContent,
          OptionLayout.tiles => _tileContent,
          OptionLayout.grid => _gridContent,
        },
      ),
    );
  }

  EdgeInsets get _padding => switch (layout) {
        OptionLayout.rows => EdgeInsets.symmetric(horizontal: 20.w, vertical: 19.h),
        OptionLayout.tiles => EdgeInsets.all(10.r),
        OptionLayout.grid => EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
      };

  double get _radius => switch (layout) {
        OptionLayout.rows => 22.r,
        OptionLayout.tiles => 18.r,
        OptionLayout.grid => 20.r,
      };

  Widget get _rowContent => Row(
        children: [
          if (icon != null) ...[
            Text(icon!, style: TextStyle(fontSize: 26.sp, height: 1)),
            SizedBox(width: 18.w),
          ],
          Expanded(
            child: Text(
              label,
              style: serif ? AppTextStyles.optionRowSerif : AppTextStyles.optionRow,
            ),
          ),
          if (chip != null) ...[SizedBox(width: 12.w), _Chip(text: chip!)],
        ],
      );

  Widget get _tileContent => Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.optionGrid,
        ),
      );

  Widget get _gridContent => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Text(icon!, style: TextStyle(fontSize: 26.sp, height: 1)),
            SizedBox(height: 11.h),
          ],
          Text(label, textAlign: TextAlign.center, style: AppTextStyles.optionGrid),
        ],
      );
}

/// Outlined pill showing a currency code.
class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 6.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.trackDark),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(text, style: AppTextStyles.chip),
    );
  }
}
