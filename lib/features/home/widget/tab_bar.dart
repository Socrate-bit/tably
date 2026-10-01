import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/haptics.dart';
import '../../../core/widget/line_icon.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/home_cubit.dart';

/// The bottom navigation bar: a floating liquid-glass pill holding a line
/// glyph over a bold label per tab.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.current, required this.onSelected});

  final HomeTab current;
  final ValueChanged<HomeTab> onSelected;

  /// Icon size inside the pill.
  static double get _iconSize => 32.r;

  /// Glyph stroke, a touch heavier than the default to read as bold.
  static const _stroke = 2.1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tabs = <(HomeTab, LineGlyph, String)>[
      (HomeTab.menu, LineGlyph.calendar, l10n.tabMenu),
      (HomeTab.recipes, LineGlyph.book, l10n.tabRecipes),
      (HomeTab.preferences, LineGlyph.heart, l10n.tabPreferences),
      (HomeTab.account, LineGlyph.user, l10n.tabAccount),
    ];
    // Inactive tabs are warm grey, as in the design.
    const idle = AppColors.textQuaternary;

    return GlassTabBar.bottom(
      selectedIndex: tabs.indexWhere((t) => t.$1 == current),
      onTabSelected: (index) {
        Haptics.tap();
        onSelected(tabs[index].$1);
      },
      // The shell owns the margins around the pill.
      horizontalPadding: 0,
      verticalPadding: 0,
      barHeight: 92.h,
      barBorderRadius: 64.r,
      iconSize: _iconSize,
      textStyle: AppTextStyles.tabLabel,
      selectedLabelColor: AppColors.brand,
      unselectedLabelColor: idle,
      indicatorColor: AppColors.brand.withValues(alpha: 0.14),
      quality: GlassQuality.premium,
      interactionBehavior: GlassInteractionBehavior.full,
      settings: LiquidGlassSettings(
        glassColor: Colors.white.withValues(alpha: 0.94),
        thickness: 20,
        blur: 2,
      ),
      tabs: [
        for (final (_, glyph, label) in tabs)
          GlassTab(
            label: label,
            // LineIcon draws an SVG, so it tints itself rather than inheriting.
            icon: LineIcon(glyph, size: _iconSize, color: idle, strokeWidth: _stroke),
            activeIcon: LineIcon(glyph, size: _iconSize, color: AppColors.brand, strokeWidth: _stroke),
          ),
      ],
    );
  }
}
