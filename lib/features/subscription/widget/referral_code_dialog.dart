import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/subscription_cubit.dart';

/// Referral code entry, shared by the welcome screen and the account tab. A
/// valid code grants admin or creator access, which bypasses the paywall.
class ReferralCodeDialog extends StatefulWidget {
  const ReferralCodeDialog({super.key});

  /// Opens the dialog. The cubit is app-wide, so nothing needs providing.
  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const ReferralCodeDialog(),
      );

  @override
  State<ReferralCodeDialog> createState() => _ReferralCodeDialogState();
}

class _ReferralCodeDialogState extends State<ReferralCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The redeemed type flows in through the profile stream, so closing on
  /// success is all this dialog has to do.
  void _onStatusChanged(BuildContext context, SubscriptionState state) {
    if (state.redeemStatus != RedeemStatus.success) return;
    Haptics.notify();
    // Cleared before popping, while this context is still safely mounted.
    context.read<SubscriptionCubit>().clearRedeemStatus();
    Navigator.of(context).pop();
  }

  /// Only failures get UI feedback, per the app's conventions.
  String? _errorFor(AppL10n l10n, RedeemStatus status) => switch (status) {
        RedeemStatus.invalid => l10n.referralInvalid,
        RedeemStatus.exhausted => l10n.referralLimit,
        RedeemStatus.alreadyUsed => l10n.referralAlreadyUsed,
        RedeemStatus.failed => l10n.referralError,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final cubit = context.read<SubscriptionCubit>();

    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listenWhen: (previous, current) => previous.redeemStatus != current.redeemStatus,
      listener: _onStatusChanged,
      builder: (context, state) {
        final busy = state.isSubmitting;
        final error = _errorFor(l10n, state.redeemStatus);

        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
          title: Text(l10n.referralTitle, style: AppTextStyles.sheetTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.referralSubtitle, style: AppTextStyles.settingsRowSub),
              SizedBox(height: 14.h),
              TextField(
                controller: _controller,
                autofocus: true,
                enabled: !busy,
                // Codes are stored uppercase, so entry is case-insensitive.
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                style: AppTextStyles.searchInput,
                decoration: InputDecoration(hintText: l10n.referralPlaceholder),
                onSubmitted: busy ? null : cubit.redeem,
              ),
              if (error != null) ...[
                SizedBox(height: 8.h),
                Text(
                  error,
                  style: AppTextStyles.settingsRowSub.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      Haptics.tap();
                      cubit.clearRedeemStatus();
                      Navigator.of(context).pop();
                    },
              child: Text(l10n.referralCancel, style: AppTextStyles.secondaryButton),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      Haptics.confirm();
                      cubit.redeem(_controller.text);
                    },
              child: busy
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.referralSubmit,
                      style: AppTextStyles.secondaryButton.copyWith(color: AppColors.brand),
                    ),
            ),
          ],
        );
      },
    );
  }
}
