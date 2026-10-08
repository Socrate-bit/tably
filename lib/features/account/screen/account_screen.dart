import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/legal_links.dart';
import '../../../core/widget/app_sheet.dart';
import '../../../core/widget/sub_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/cubit/home_cubit.dart';
import '../../onboarding/widget/steps/language_step.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../review/cubit/review_cubit.dart';
import '../../subscription/widget/referral_code_dialog.dart';
import '../cubit/auth_cubit.dart';
import '../widget/account_rows.dart';

/// The account screen, opened from preferences: sign-in, profile and status, referral code, language,
/// legal links and account actions.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final inReview = context.select<ReviewCubit, bool>((c) => c.state.inReview);

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current.error != null && previous.error != current.error,
      listener: (context, state) {
        showErrorBanner(context, l10n.errorSignIn);
        context.read<AuthCubit>().errorShown();
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              final profile = profileState.profile;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, AppDimens.tabBarInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SubScreenHeader(title: l10n.accountTitle, onBack: context.read<HomeCubit>().closeSub),
                    SizedBox(height: 16.h),

                    // Apple sign-in only appears where it is actually available.
                    if (!authState.isSignedIn && _supportsApple) ...[
                      AppleSignInButton(
                        busy: authState.busy,
                        onPressed: context.read<AuthCubit>().signInWithApple,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        l10n.accountSignInSub,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.metaMuted.copyWith(
                          color: AppColors.textQuaternary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 22.h),
                    ],

                    ProfileSummaryCard(
                      name: profile.displayName(l10n.defaultChefName),
                      // App Review builds never name a store.
                      store: inReview ? null : profile.store.displayName,
                      onEdit: () => _editName(context, profile.name),
                    ),
                    SizedBox(height: 26.h),

                    AccountSection(
                      label: l10n.accountSectionApp,
                      rows: [
                        // App Review builds offer no referral code.
                        if (!inReview)
                          AccountRow(
                            title: l10n.accountEnterReferralCode,
                            arrow: true,
                            onTap: () => ReferralCodeDialog.show(context),
                          ),
                        AccountRow(
                          title: l10n.accountLanguage,
                          subtitle: languageFor(profile.languageCode).name,
                          arrow: true,
                          onTap: () => _pickLanguage(context),
                        ),
                      ],
                    ),
                    // Hosted on GitHub Pages and opened in the browser.
                    AccountSection(
                      label: l10n.accountSectionLegal,
                      rows: [
                        AccountRow(
                          title: l10n.accountPrivacy,
                          arrow: true,
                          onTap: () => openLegalLink(context, LegalLinks.privacyPolicy),
                        ),
                        AccountRow(
                          title: l10n.accountTerms,
                          arrow: true,
                          onTap: () => openLegalLink(context, LegalLinks.terms),
                        ),
                      ],
                    ),
                    AccountSection(
                      label: l10n.accountSectionAccount,
                      rows: [
                        // An anonymous user has nothing to sign out of — doing
                        // so would only orphan their data.
                        if (authState.isSignedIn)
                          AccountRow(
                            title: l10n.accountSignOut,
                            arrow: true,
                            onTap: () => _signOut(context),
                          ),
                        AccountRow(
                          title: l10n.accountDelete,
                          titleColor: AppColors.danger,
                          onTap: () => _confirmDelete(context),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Apple sign-in is only offered on Apple platforms.
  bool get _supportsApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Reuses the onboarding language picker in a sheet. The saved language
  /// drives the app locale, so the switch applies immediately.
  Future<void> _pickLanguage(BuildContext context) {
    final profileCubit = context.read<ProfileCubit>();
    return AppSheet.show<void>(
      context,
      (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 30.h),
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusSheet)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: LanguagePicker(
              onSelected: (code) {
                Navigator.of(sheetContext).pop();
                profileCubit.setLanguage(code);
              },
              onBack: () => Navigator.of(sheetContext).pop(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, String current) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current),
    );
    if (result != null && context.mounted) {
      await context.read<ProfileCubit>().setName(result);
    }
  }

  /// Deleting an account is irreversible, so it always asks first.
  /// Signs out, then returns the shell to its first tab for the next user.
  Future<void> _signOut(BuildContext context) async {
    // Read before the await: signing out unmounts this screen.
    final home = context.read<HomeCubit>();
    if (await context.read<AuthCubit>().signOut()) home.reset();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppL10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
        title: Text(l10n.accountDelete, style: AppTextStyles.sheetTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.ratingNotNow, style: AppTextStyles.secondaryButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.accountDelete,
              style: AppTextStyles.secondaryButton.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Haptics.notify();
      // Read before the await: deleting the account unmounts this screen.
      final home = context.read<HomeCubit>();
      if (await context.read<AuthCubit>().deleteAccount()) home.reset();
    }
  }
}

/// Name editor. Owns its controller so it is disposed only after the dialog's
/// close animation — disposing it when showDialog returns crashes the TextField.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: AppTextStyles.searchInput,
        decoration: InputDecoration(hintText: l10n.onbNamePlaceholder),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ratingNotNow, style: AppTextStyles.secondaryButton),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(
            l10n.actionContinue,
            style: AppTextStyles.secondaryButton.copyWith(color: AppColors.brand),
          ),
        ),
      ],
    );
  }
}
