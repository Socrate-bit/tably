import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/user_type.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../subscription/cubit/subscription_cubit.dart';

/// Black pill button for Apple sign-in.
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({super.key, required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy
          ? null
          : () {
              Haptics.confirm();
              onPressed();
            },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 17.h),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(32.r),
        ),
        child: busy
            ? Center(
                child: SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.surface,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('', style: AppTextStyles.emojiIcon.copyWith(fontSize: 18.sp, color: AppColors.surface)),
                  SizedBox(width: 9.w),
                  Text(
                    AppL10n.of(context).accountSignInApple,
                    style: AppTextStyles.primaryButtonSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

/// "Salut, Chef ✎" with the store subtitle and the Active pill.
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.name,
    required this.store,
    required this.onEdit,
  });

  final String name;
  final String store;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return SurfaceCard(
      padding: EdgeInsets.all(18.r),
      onTap: onEdit,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.accountGreeting(name),
                  style: AppTextStyles.sheetTitle.copyWith(fontSize: 18.sp),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.accountShoppingAt(store),
                  style: AppTextStyles.metaMuted.copyWith(color: AppColors.textQuaternary),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          const ActivePill(compact: true),
        ],
      ),
    );
  }
}

/// The subscription pill: what the user is currently entitled to.
class ActivePill extends StatelessWidget {
  const ActivePill({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final state = context.watch<SubscriptionCubit>().state;

    // A referral grant outranks the subscription, and reads more usefully.
    final (label, background, foreground) = switch (state.userType) {
      UserType.admin => (l10n.accountPlanAdmin, AppColors.brandChip, AppColors.brandDarker),
      UserType.ugc => (l10n.accountPlanUgc, AppColors.brandChip, AppColors.brandDarker),
      UserType.normal when state.isActive =>
        (l10n.accountActive, AppColors.brandChip, AppColors.brandDarker),
      UserType.normal => (l10n.accountPlanFree, AppColors.fill, AppColors.textPlaceholder),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: (compact ? 13 : 14).w, vertical: (compact ? 5 : 6).h),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20.r)),
      child: Text(
        label,
        style: AppTextStyles.chip.copyWith(color: foreground, fontWeight: FontWeight.w800, letterSpacing: 0),
      ),
    );
  }
}

/// One row inside an account section.
class AccountRow {
  const AccountRow({
    required this.title,
    this.subtitle,
    this.arrow = false,
    this.toggleValue,
    this.onToggle,
    this.onTap,
    this.titleColor = AppColors.ink,
  });

  final String title;
  final String? subtitle;
  final bool arrow;

  /// Non-null renders a switch instead of a chevron.
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;
  final Color titleColor;
}

/// A labelled group of rows in one card.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key, required this.label, required this.rows});

  final String label;
  final List<AccountRow> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Text(label, style: AppTextStyles.groupLabelSmall),
          ),
          SurfaceCard(
            clip: true,
            child: Column(
              children: [
                for (final (index, row) in rows.indexed)
                  _Row(row: row, isLast: index == rows.length - 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.isLast});

  final AccountRow row;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: row.onTap == null
          ? null
          : () {
              Haptics.tap();
              row.onTap!();
            },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    row.title,
                    style: AppTextStyles.settingsRowTitle.copyWith(color: row.titleColor),
                  ),
                  if (row.subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(row.subtitle!, style: AppTextStyles.settingsRowSub),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12.w),
            if (row.toggleValue != null)
              _Toggle(
                value: row.toggleValue!,
                onChanged: (value) {
                  Haptics.toggle();
                  row.onToggle?.call(value);
                },
              )
            else if (row.arrow)
              Text('›', style: AppTextStyles.emojiIcon.copyWith(color: AppColors.chevron, fontSize: 18.sp)),
          ],
        ),
      ),
    );
  }
}

/// Pill switch matching the design's dimensions.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 50.w,
        height: 30.h,
        padding: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          color: value ? AppColors.brand : AppColors.toggleOff,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26.r,
            height: 26.r,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 3.r,
                  offset: Offset(0, 1.h),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
