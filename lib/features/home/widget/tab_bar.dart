import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/line_icon.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/home_cubit.dart';

/// The bottom navigation bar: a line glyph over a bold label.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.current, required this.onSelected});

  final HomeTab current;
  final ValueChanged<HomeTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tabs = <(HomeTab, LineGlyph, String)>[
      (HomeTab.menu, LineGlyph.calendar, l10n.tabMenu),
      (HomeTab.recipes, LineGlyph.book, l10n.tabRecipes),
      (HomeTab.preferences, LineGlyph.heart, l10n.tabPreferences),
      (HomeTab.account, LineGlyph.user, l10n.tabAccount),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.scaffold,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(8.w, 11.h, 8.w, 8.h),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: 14.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final (tab, glyph, label) in tabs)
              _TabButton(glyph: glyph, label: label, selected: tab == current, onTap: () => onSelected(tab)),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.glyph, required this.label, required this.selected, required this.onTap});

  final LineGlyph glyph;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brand : AppColors.ink;
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        // Inactive tabs are ink at a third strength, as in the design.
        opacity: selected ? 1 : 0.34,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LineIcon(glyph, size: 23.r, color: color),
              SizedBox(height: 4.h),
              Text(label, style: AppTextStyles.tabLabel.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
