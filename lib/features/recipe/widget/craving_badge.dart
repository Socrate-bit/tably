import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/model/preference_option.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/option_labels.dart';
import '../../../l10n/app_localizations.dart';

/// The coloured pill naming a recipe's craving ("Repas express").
class CravingBadge extends StatelessWidget {
  const CravingBadge({super.key, required this.craving});

  final Craving craving;

  /// Badge colours from the design; anything unlisted uses the protein pink.
  static (Color, Color) colorsFor(Craving craving) => switch (craving) {
        Craving.quick => (AppColors.badgeQuickBg, AppColors.badgeQuickInk),
        Craving.indulgent => (AppColors.badgeIndulgentBg, AppColors.badgeIndulgentInk),
        _ => (AppColors.badgeProteinBg, AppColors.badgeProteinInk),
      };

  @override
  Widget build(BuildContext context) {
    final (background, ink) = colorsFor(craving);
    return Container(
      margin: EdgeInsets.only(top: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20.r)),
      child: Text(
        AppL10n.of(context).cravingLabel(craving),
        style: AppTextStyles.badgeSmall.copyWith(color: ink),
        maxLines: 1,
      ),
    );
  }
}
