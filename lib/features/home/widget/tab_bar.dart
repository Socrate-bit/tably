import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/home_cubit.dart';

/// The bottom navigation bar: emoji glyph over a bold label.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.current, required this.onSelected});

  final HomeTab current;
  final ValueChanged<HomeTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tabs = <(HomeTab, String, String)>[
      (HomeTab.menu, '📋', l10n.tabMenu),
      (HomeTab.recipes, '🍽', l10n.tabRecipes),
      (HomeTab.preferences, '♥', l10n.tabPreferences),
      (HomeTab.account, '⚙️', l10n.tabAccount),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.scaffold,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(8.w, 11.h, 8.w, 6.h),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final (tab, icon, label) in tabs)
              _TabButton(
                icon: icon,
                label: label,
                selected: tab == current,
                onTap: () => onSelected(tab),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brand : AppColors.textDisabled;
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: selected ? 1 : 0.75,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: TextStyle(fontSize: 23.sp, height: 1, color: color)),
              SizedBox(height: 4.h),
              Text(label, style: AppTextStyles.tabLabel.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
