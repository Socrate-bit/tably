import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';

/// The gradient "↻" pill, such as "régénérer le plan" or "relancer la
/// recherche"; its icon spins while [regenerating].
class RegenerateButton extends StatefulWidget {
  const RegenerateButton({super.key, required this.label, required this.regenerating, required this.onPressed});

  final String label;
  final bool regenerating;
  final VoidCallback onPressed;

  @override
  State<RegenerateButton> createState() => _RegenerateButtonState();
}

class _RegenerateButtonState extends State<RegenerateButton> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didUpdateWidget(RegenerateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.regenerating ? _spin.repeat() : _spin.reset();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.confirm();
        widget.onPressed();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 13.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          // 100deg in CSS runs almost horizontally, slightly downward.
          gradient: const LinearGradient(
            begin: Alignment(-1, -0.18),
            end: Alignment(1, 0.18),
            colors: [AppColors.brandLight, AppColors.brandDeep],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.brand.withValues(alpha: 0.26), blurRadius: 18.r, offset: Offset(0, 6.h)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _spin,
              child: Container(
                width: 24.r,
                height: 24.r,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                child: Text('↻', style: AppTextStyles.regenerate.copyWith(color: AppColors.brandDark, fontSize: 13.sp)),
              ),
            ),
            SizedBox(width: 9.w),
            Text(widget.label, style: AppTextStyles.regenerate),
          ],
        ),
      ),
    );
  }
}
