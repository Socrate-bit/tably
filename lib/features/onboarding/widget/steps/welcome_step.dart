import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widget/circle_icon_button.dart';
import '../../../../core/widget/primary_button.dart';
import '../../../../l10n/app_localizations.dart';

/// The branded welcome screen with the phone mock-up and page dots.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onBack, required this.onNext, required this.storeName});

  final VoidCallback onBack;
  final VoidCallback onNext;

  /// Shown inside the mock-up's "prévu pour …" chip.
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(bottom: 22.h),
            child: CircleIconButton(glyph: '←', onPressed: onBack),
          ),
        ),
        Column(
          children: [
            Text('🥗', style: TextStyle(fontSize: 30.sp, height: 1)),
            SizedBox(height: 2.h),
            Text(l10n.appName, style: AppTextStyles.wordmarkLarge),
          ],
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.only(bottom: 26.h),
          child: Text(l10n.tagline, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
        ),
        _PhoneMockup(storeName: storeName),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 7.r,
                height: 7.r,
                margin: EdgeInsets.symmetric(horizontal: 3.5.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == 0 ? AppColors.inkStrong : AppColors.neutralBar,
                ),
              ),
          ],
        ),
        const Spacer(),
        PrimaryButton(label: l10n.actionStart, trailing: '→', onPressed: onNext),
        SizedBox(height: 16.h),
        Text(l10n.haveACode, textAlign: TextAlign.center, style: AppTextStyles.metaSmall.copyWith(
          fontSize: 14.sp,
          color: AppColors.textDisabled,
        )),
      ],
    );
  }
}

/// Miniature of the menu screen, flanked by two faded side panels.
class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({required this.storeName});

  final String storeName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _SidePanel(),
        SizedBox(width: 8.w),
        Container(
          width: 150.w,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.ink, width: 7.w),
            borderRadius: BorderRadius.circular(28.r),
          ),
          child: Column(
            children: [
              Text(
                'BON APRÈS-MIDI',
                style: TextStyle(
                  fontSize: 8.sp,
                  color: AppColors.textPlaceholder,
                  letterSpacing: 1.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                '${l10n.defaultChefName} !',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              SizedBox(height: 7.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(5.r),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  l10n.plannedFor(storeName),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 8.sp, color: AppColors.brandDark, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: 7.h),
              Row(
                children: [
                  const Expanded(child: _MockTile(height: 34, tinted: false)),
                  SizedBox(width: 5.w),
                  const Expanded(child: _MockTile(height: 34, tinted: true)),
                ],
              ),
              SizedBox(height: 7.h),
              for (var i = 0; i < 3; i++) ...[
                const _MockTile(height: 30, tinted: false),
                if (i < 2) SizedBox(height: 7.h),
              ],
            ],
          ),
        ),
        SizedBox(width: 8.w),
        const _SidePanel(),
      ],
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Container(
        width: 44.w,
        height: 190.h,
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }
}

class _MockTile extends StatelessWidget {
  const _MockTile({required this.height, required this.tinted});

  final double height;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.h,
      decoration: BoxDecoration(
        color: tinted ? AppColors.info : AppColors.surfaceTinted,
        border: tinted ? null : Border.all(color: AppColors.borderSoft),
        borderRadius: BorderRadius.circular(9.r),
      ),
    );
  }
}
