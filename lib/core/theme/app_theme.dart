import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

export 'app_colors.dart';
export 'app_dimens.dart';
export 'app_text_styles.dart';

/// Builds the single [ThemeData] for the app.
abstract final class AppTheme {
  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        primary: AppColors.brand,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.scaffold,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );

    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: AppColors.trackDark,
        inactiveTrackColor: AppColors.trackDark,
        thumbColor: AppColors.brand,
        overlayColor: Colors.transparent,
        trackHeight: 7,
      ),
    );
  }
}
