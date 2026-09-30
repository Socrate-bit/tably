import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/cubit/onboarding_cubit.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../recipe/cubit/recipe_cubit.dart';
import '../../subscription/cubit/subscription_cubit.dart';
import '../../subscription/widget/referral_code_dialog.dart';
import '../cubit/auth_cubit.dart';
import '../widget/account_rows.dart';

/// The account tab: sign-in, family plan, app settings and legal links.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

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
              final recipeCubit = context.read<RecipeCubit>();
              final userType = context.watch<SubscriptionCubit>().state.userType;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, AppDimens.tabBarInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(l10n.accountTitle, style: AppTextStyles.tabTitle)),
                        const ActivePill(),
                      ],
                    ),
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

                    const FamilyPlanCard(),
                    SizedBox(height: 18.h),
                    ProfileSummaryCard(
                      name: profile.displayName(l10n.defaultChefName),
                      store: profile.store.displayName,
                      onEdit: () => _editName(context, profile.name),
                    ),
                    SizedBox(height: 26.h),

                    AccountSection(
                      label: l10n.accountSectionApp,
                      rows: [
                        AccountRow(title: l10n.accountRateTably, arrow: true, onTap: () {}),
                        AccountRow(title: l10n.accountSuggestFeature, arrow: true, onTap: () {}),
                        AccountRow(
                          title: l10n.accountLanguage,
                          subtitle: _languageName(profile.languageCode),
                          arrow: true,
                          onTap: () {},
                        ),
                        AccountRow(
                          title: l10n.accountResetSaved,
                          subtitle: l10n.accountResetSavedSub,
                          arrow: true,
                          onTap: () => recipeCubit.reset(favouritesOnly: true),
                        ),
                        AccountRow(
                          title: l10n.accountResetHistory,
                          subtitle: l10n.accountResetHistorySub,
                          arrow: true,
                          onTap: () => recipeCubit.reset(favouritesOnly: false),
                        ),
                        AccountRow(
                          title: l10n.accountEnterReferralCode,
                          arrow: true,
                          onTap: () => ReferralCodeDialog.show(context),
                        ),
                      ],
                    ),
                    AccountSection(
                      label: l10n.accountSectionAlerts,
                      rows: [
                        AccountRow(
                          title: l10n.accountWeeklyReminder,
                          subtitle: l10n.accountWeeklyReminderSub,
                          toggleValue: profile.weeklyReminder,
                          onToggle: context.read<ProfileCubit>().setWeeklyReminder,
                        ),
                      ],
                    ),
                    AccountSection(
                      label: l10n.accountSectionHelp,
                      rows: [
                        AccountRow(title: l10n.accountShareTably, arrow: true, onTap: () {}),
                        AccountRow(title: l10n.accountContactUs, arrow: true, onTap: () {}),
                        AccountRow(title: l10n.accountManageSubscription, arrow: true, onTap: () {}),
                      ],
                    ),
                    AccountSection(
                      label: l10n.accountSectionLegal,
                      rows: [
                        AccountRow(title: l10n.accountPrivacy, arrow: true, onTap: () {}),
                        AccountRow(title: l10n.accountTerms, arrow: true, onTap: () {}),
                      ],
                    ),
                    // Only admins and creators, granted by a referral code.
                    if (userType.canReplayOnboarding)
                      AccountSection(
                        label: l10n.accountSectionCreator,
                        rows: [
                          AccountRow(
                            title: l10n.accountReplayOnboarding,
                            subtitle: l10n.accountReplayOnboardingSub,
                            arrow: true,
                            onTap: () => _replayOnboarding(context, profile.languageCode),
                          ),
                        ],
                      ),
                    AccountSection(
                      label: l10n.accountSectionAccount,
                      rows: [
                        if (authState.isSignedIn)
                          AccountRow(
                            title: l10n.accountSignOut,
                            arrow: true,
                            onTap: context.read<AuthCubit>().signOut,
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

  /// Resets the funnel before clearing the flag: [RootScreen] swaps screens the
  /// moment the profile stream reports it, and a stale cubit would flash the
  /// last step the user saw.
  void _replayOnboarding(BuildContext context, String languageCode) {
    context.read<OnboardingCubit>().restart(languageCode);
    context.read<ProfileCubit>().replayOnboarding();
  }

  String _languageName(String code) => switch (code) {
        'en' => 'English',
        'de' => 'Deutsch',
        'sv' => 'Svenska',
        'nl' => 'Nederlands',
        'pt' => 'Português',
        'es' => 'Español',
        _ => 'Français',
      };

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
      await context.read<AuthCubit>().deleteAccount();
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
