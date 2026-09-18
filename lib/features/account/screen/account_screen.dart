import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../../recipe/cubit/recipe_cubit.dart';
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

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.accountEyebrow, textAlign: TextAlign.center, style: AppTextStyles.eyebrow),
                    SizedBox(height: 4.h),
                    Text(
                      l10n.accountTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle,
                    ),
                    SizedBox(height: 22.h),

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
                      store: profile.store,
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
  bool get _supportsApple => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

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
    final controller = TextEditingController(text: current);
    final l10n = AppL10n.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.searchInput,
          decoration: InputDecoration(hintText: l10n.onbNamePlaceholder),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.ratingNotNow, style: AppTextStyles.secondaryButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(
              l10n.actionContinue,
              style: AppTextStyles.secondaryButton.copyWith(color: AppColors.brand),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
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
