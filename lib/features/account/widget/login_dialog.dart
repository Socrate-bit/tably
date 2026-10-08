import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/auth_cubit.dart';

/// Email/password sign-in into an existing account. Only offered to App Review
/// builds on the welcome screen, so reviewers can open the demo account.
class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  /// Opens the dialog. The cubit is app-wide, so nothing needs providing.
  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const LoginDialog(),
      );

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// The signed-in profile flows in through the auth stream, which takes the
  /// app past onboarding; the dialog only has to close.
  Future<void> _submit() async {
    Haptics.confirm();
    final ok = await context.read<AuthCubit>().signInWithEmail(_email.text, _password.text);
    if (ok && mounted) Navigator.of(context).pop();
  }

  void _cancel() {
    Haptics.tap();
    context.read<AuthCubit>().errorShown();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final state = context.watch<AuthCubit>().state;
    final busy = state.busy;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      title: Text(l10n.loginTitle, style: AppTextStyles.sheetTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _email,
            autofocus: true,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            style: AppTextStyles.searchInput,
            decoration: InputDecoration(hintText: l10n.loginEmail),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _password,
            enabled: !busy,
            obscureText: true,
            textInputAction: TextInputAction.done,
            style: AppTextStyles.searchInput,
            decoration: InputDecoration(hintText: l10n.loginPassword),
            onSubmitted: busy ? null : (_) => _submit(),
          ),
          if (state.error != null) ...[
            SizedBox(height: 8.h),
            Text(
              l10n.loginError,
              style: AppTextStyles.settingsRowSub.copyWith(fontSize: 13.sp, color: AppColors.danger),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : _cancel,
          child: Text(l10n.referralCancel, style: AppTextStyles.secondaryButton),
        ),
        TextButton(
          onPressed: busy ? null : _submit,
          child: busy
              ? SizedBox(width: 18.r, height: 18.r, child: const CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.loginTitle, style: AppTextStyles.secondaryButton.copyWith(color: AppColors.brand)),
        ),
      ],
    );
  }
}
