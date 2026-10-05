import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/util/haptics.dart';
import '../../../core/util/option_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/catalogue_cubit.dart';
import '../cubit/search_quota_cubit.dart';

/// Shows a failed recipe build or search: the quota pop-up when the day's
/// searches are spent, a banner for anything else.
void showSearchError(BuildContext context, Object? error) {
  if (CatalogueCubit.reasonFor(error) != 'quota') {
    showErrorBanner(context, AppL10n.of(context).catalogueError(error));
    return;
  }
  if (!context.mounted) return;
  Haptics.notify();
  QuotaDialog.show(context);
}

/// The day's recipe searches: how many are left, or that none are, and when
/// they come back (midnight UTC, shown in the user's local time).
class QuotaDialog extends StatelessWidget {
  const QuotaDialog({super.key});

  static Future<void> show(BuildContext context) =>
      showDialog<void>(context: context, builder: (_) => const QuotaDialog());

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final quota = context.watch<SearchQuotaCubit>().state;
    final time = TimeOfDay.fromDateTime(quota.resetsAt.toLocal()).format(context);
    final spent = quota.remaining == 0;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      title: Text(spent ? l10n.quotaReachedTitle : l10n.quotaTitle, style: AppTextStyles.sheetTitle),
      content: Text(
        spent
            ? l10n.quotaReachedBody(quota.limit, time)
            : l10n.quotaBody(quota.remaining, quota.limit, time),
        style: AppTextStyles.settingsRowSub,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Haptics.tap();
            Navigator.of(context).pop();
          },
          child: Text(l10n.actionOk, style: AppTextStyles.secondaryButton),
        ),
      ],
    );
  }
}
