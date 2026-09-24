import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../util/haptics.dart';

/// "− 2 +  personnes". [compact] is the smaller preferences variant.
class HouseholdStepper extends StatelessWidget {
  const HouseholdStepper({
    super.key,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
    this.compact = false,
  });

  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gap = (compact ? 30 : 36).w;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepperButton(glyph: '−', size: compact ? 46 : 56, enabled: count > 1, onTap: onDecrement),
            SizedBox(width: gap),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: (compact ? 44 : 64).w),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: compact ? AppTextStyles.numeralSmall : AppTextStyles.numeral,
              ),
            ),
            SizedBox(width: gap),
            _StepperButton(glyph: '+', size: compact ? 46 : 56, enabled: true, onTap: onIncrement),
          ],
        ),
        SizedBox(height: (compact ? 8 : 14).h),
        Text(
          AppL10n.of(context).peopleCount(count),
          style: (compact ? AppTextStyles.caption : AppTextStyles.subtitleLarge).copyWith(color: AppColors.textQuaternary),
        ),
      ],
    );
  }
}

/// Round grey +/− control. Disabled only dims the glyph, as in the design.
class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.glyph, required this.size, required this.enabled, required this.onTap});

  final String glyph;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              Haptics.toggle();
              onTap();
            }
          : null,
      child: Container(
        width: size.r,
        height: size.r,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.fill, shape: BoxShape.circle),
        child: Text(
          glyph,
          style: AppTextStyles.emojiIcon.copyWith(
            fontSize: (size * 0.46).sp,
            fontWeight: FontWeight.w500,
            color: enabled ? AppColors.inkStrong : AppColors.chevron,
          ),
        ),
      ),
    );
  }
}
