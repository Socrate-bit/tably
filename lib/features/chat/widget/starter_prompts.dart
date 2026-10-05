import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';

/// What an empty conversation shows: a greeting and a few things to ask.
class StarterPrompts extends StatelessWidget {
  const StarterPrompts({super.key, required this.onPicked});

  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final prompts = [l10n.chatStarterTonight, l10n.chatStarterFridge, l10n.chatStarterRule, l10n.chatStarterLighter];
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppDimens.pageH, vertical: 12.h),
      children: [
        Text('👨‍🍳', style: AppTextStyles.emojiIcon.copyWith(fontSize: 44.sp)),
        SizedBox(height: 12.h),
        Text(l10n.chatEmptyTitle, style: AppTextStyles.h2),
        SizedBox(height: 6.h),
        Text(l10n.chatEmptySubtitle, style: AppTextStyles.subtitle),
        SizedBox(height: 22.h),
        for (final prompt in prompts)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: SurfaceCard(
              radius: AppDimens.radiusTile,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              onTap: () => onPicked(prompt),
              child: Text(prompt, style: AppTextStyles.settingsRowTitle),
            ),
          ),
      ],
    );
  }
}
