import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../core/widget/primary_button.dart';
import '../../../core/widget/slide_in.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/onboarding_cubit.dart';

/// "Bonne nouvelle": the same week would cost less at another store.
class StoreSwitchScreen extends StatelessWidget {
  const StoreSwitchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final cubit = context.read<OnboardingCubit>();
    final state = context.watch<OnboardingCubit>().state;
    final draft = state.draft;
    final week = state.previewWeek;
    final current = draft.store;
    final rival = state.cheaperStore;

    return SlideIn(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 26.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('💸', textAlign: TextAlign.center, style: AppTextStyles.emojiIcon.copyWith(fontSize: 64.sp)),
                  SizedBox(height: 10.h),
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
                      decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(22.r)),
                      child: Text(
                        l10n.switchEyebrow,
                        style: AppTextStyles.savings.copyWith(letterSpacing: 0.6.sp),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.switchTitle,
                      children: [
                        TextSpan(text: l10n.switchTitlePrefix),
                        TextSpan(
                          text: l10n.switchTitleHighlight(state.switchSavingPercent),
                          style: AppTextStyles.switchTitle.copyWith(color: AppColors.brand),
                        ),
                        TextSpan(text: l10n.switchTitleSuffix(rival.displayName)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    l10n.switchSubtitle(current.displayName),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PriceColumn(
                            label: current.displayName.toUpperCase(),
                            price: formatMoney(draft.country, week.totalAt(current)),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Text('→', style: AppTextStyles.emojiIcon.copyWith(color: AppColors.chevron)),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
                            decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(18.r)),
                            child: _PriceColumn(
                              label: rival.displayName.toUpperCase(),
                              price: formatMoney(draft.country, week.totalAt(rival)),
                              highlighted: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            PrimaryButton(label: l10n.switchAccept(rival.displayName), onPressed: cubit.acceptStoreSwitch),
            SizedBox(height: 4.h),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Haptics.tap();
                cubit.declineStoreSwitch();
              },
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Text(
                  l10n.switchDecline(current.displayName),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.listItemTitle.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({required this.label, required this.price, this.highlighted = false});

  final String label;
  final String price;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.switchStoreLabel.copyWith(color: highlighted ? AppColors.brandDark : null),
        ),
        SizedBox(height: 4.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(price, style: AppTextStyles.switchPrice.copyWith(color: highlighted ? AppColors.brand : null)),
        ),
      ],
    );
  }
}
