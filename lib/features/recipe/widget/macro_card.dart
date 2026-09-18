import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';
import '../model/recipe.dart';

/// Per-serving macro breakdown: four colour-coded figures in a row.
class MacroCard extends StatelessWidget {
  const MacroCard({super.key, required this.macros});

  final Macros macros;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final entries = <(String, String, Color)>[
      ('${macros.kcal}', l10n.macroKcal, AppColors.inkStrong),
      ('${macros.protein}g', l10n.macroProtein, AppColors.danger),
      ('${macros.carbs}g', l10n.macroCarbs, AppColors.carbs),
      ('${macros.fat}g', l10n.macroFat, AppColors.brandDark),
    ];

    return SurfaceCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.h),
      child: Column(
        children: [
          Text(l10n.recipeMacros, style: AppTextStyles.cardLabelBrand),
          SizedBox(height: 16.h),
          Row(
            children: [
              for (final (value, label, color) in entries)
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(value, style: AppTextStyles.statValue.copyWith(color: color)),
                      ),
                      SizedBox(height: 2.h),
                      Text(label, style: AppTextStyles.statLabel),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
