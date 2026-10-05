import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/input_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../model/user_profile.dart';

/// The user's own rules as removable chips, with a field to add one.
class CustomPreferences extends StatelessWidget {
  const CustomPreferences({super.key, required this.rules, required this.onAdd, required this.onRemove});

  final List<String> rules;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rules.isNotEmpty) ...[
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [for (final rule in rules) _RuleChip(rule: rule, onRemove: () => onRemove(rule))],
          ),
          SizedBox(height: 12.h),
        ],
        if (rules.length < UserProfile.maxCustomPreferences)
          InputBar(
            hint: AppL10n.of(context).prefsCustomHint,
            maxLength: UserProfile.maxCustomPreferenceLength,
            onSubmitted: onAdd,
          ),
      ],
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.rule, required this.onRemove});

  final String rule;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.toggle();
        onRemove();
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 10.w, 8.h),
        decoration: BoxDecoration(
          color: AppColors.brandSoft,
          border: Border.all(color: AppColors.brandSoftBorder),
          borderRadius: BorderRadius.circular(AppDimens.radiusChip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(rule, style: AppTextStyles.secondaryButton.copyWith(color: AppColors.brandSoftInk))),
            SizedBox(width: 8.w),
            Text('✕', style: AppTextStyles.metaSmall.copyWith(color: AppColors.brandSoftInk)),
          ],
        ),
      ),
    );
  }
}
