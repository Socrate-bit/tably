import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../util/haptics.dart';

/// A two-option pill switch. [compact] is the smaller variant used in sheets.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.first,
    required this.second,
    required this.firstSelected,
    required this.onChanged,
    this.compact = false,
  });

  final String first;
  final String second;
  final bool firstSelected;

  /// Called with true when the first option is chosen.
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, bool active, bool value) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (active) return;
              Haptics.tap();
              onChanged(value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(vertical: compact ? 11.h : 13.h),
              decoration: BoxDecoration(
                color: active ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(compact ? 22.r : 28.r),
                boxShadow: active
                    ? [BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 3.r, offset: Offset(0, 1.h))]
                    : null,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.segmentedLabel.copyWith(
                  fontSize: compact ? 15.sp : null,
                  color: active
                      ? AppColors.brandDark
                      : (compact ? AppColors.textQuaternary : AppColors.textTertiary),
                ),
              ),
            ),
          ),
        );

    return Container(
      padding: EdgeInsets.all(compact ? 4.r : 5.r),
      decoration: BoxDecoration(
        color: compact ? AppColors.surfaceMuted : AppColors.fill,
        borderRadius: BorderRadius.circular(compact ? 26.r : 32.r),
      ),
      child: Row(children: [segment(first, firstSelected, true), segment(second, !firstSelected, false)]),
    );
  }
}
