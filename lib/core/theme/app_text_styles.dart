import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Every text style in the app. The design uses Manrope throughout, with Bitter
/// reserved for the serif accents (language + country pickers).
abstract final class AppTextStyles {
  static TextStyle _sans(
    double size,
    FontWeight weight, {
    Color color = AppColors.ink,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.manrope(
        fontSize: size.sp,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing.sp,
        height: height,
      );

  static TextStyle _serif(
    double size,
    FontWeight weight, {
    Color color = AppColors.ink,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.bitter(
        fontSize: size.sp,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing.sp,
      );

  // ---- Display / headings ----
  /// Onboarding language screen title.
  static TextStyle get h1Large => _sans(34, FontWeight.w800, letterSpacing: -1.2);

  /// Standard onboarding question title.
  static TextStyle get h1 => _sans(31, FontWeight.w800, letterSpacing: -1, height: 1.1);

  /// Centred info-step title.
  static TextStyle get h1Center => _sans(30, FontWeight.w800, letterSpacing: -1, height: 1.15);

  /// Tab screen title ("explorer", "préférence", "compte").
  static TextStyle get screenTitle => _sans(31, FontWeight.w800, letterSpacing: -1);

  /// Tably wordmark.
  static TextStyle get wordmark => _sans(34, FontWeight.w800, color: AppColors.brand, letterSpacing: -1.8);

  static TextStyle get wordmarkLarge => _sans(40, FontWeight.w800, color: AppColors.brand, letterSpacing: -1.6);

  static TextStyle get wordmarkGenerating =>
      _sans(34, FontWeight.w800, color: AppColors.brand, letterSpacing: -1.6);

  /// Big numeric readouts (household count, budget, savings).
  static TextStyle get numeral => _sans(58, FontWeight.w800, letterSpacing: -2);

  static TextStyle get numeralCurrency => _sans(58, FontWeight.w800, letterSpacing: -2.5);

  static TextStyle get numeralBrand =>
      _sans(58, FontWeight.w800, color: AppColors.brand, letterSpacing: -2);

  static TextStyle get numeralSmall => _sans(36, FontWeight.w800, letterSpacing: -1.5);

  static TextStyle get h2 => _sans(25, FontWeight.w800, letterSpacing: -0.8);

  static TextStyle get h2Bars => _sans(23, FontWeight.w800, letterSpacing: -0.6, height: 1.2);

  /// Section heading inside a tab ("Tes envies", "Pays", …).
  static TextStyle get sectionTitle => _sans(23, FontWeight.w800, letterSpacing: -0.6);

  static TextStyle get settingsSectionTitle => _sans(22, FontWeight.w800, letterSpacing: -0.5);

  /// Recipe detail title.
  static TextStyle get recipeTitle => _sans(24, FontWeight.w800, letterSpacing: -0.7, height: 1.2);

  static TextStyle get sheetTitle => _sans(20, FontWeight.w800, letterSpacing: -0.4);

  // ---- Body ----
  static TextStyle get subtitle =>
      _sans(16, FontWeight.w500, color: AppColors.textSecondary, height: 1.45);

  static TextStyle get subtitleTight =>
      _sans(16, FontWeight.w500, color: AppColors.textSecondary, height: 1.35);

  static TextStyle get subtitleLarge =>
      _sans(17, FontWeight.w500, color: AppColors.textSecondary, height: 1.45);

  static TextStyle get hint => _sans(15, FontWeight.w500, color: AppColors.textQuaternary);

  static TextStyle get caption => _sans(15, FontWeight.w500, color: AppColors.textTertiary);

  static TextStyle get body => _sans(15, FontWeight.w500, color: AppColors.inkBody, height: 1.45);

  static TextStyle get bodyMuted => _sans(15, FontWeight.w500, color: AppColors.inkMuted);

  static TextStyle get meta => _sans(14, FontWeight.w600, color: AppColors.textSecondary);

  static TextStyle get metaMuted => _sans(14, FontWeight.w500, color: AppColors.textPlaceholder);

  static TextStyle get metaSmall => _sans(13, FontWeight.w600, color: AppColors.textPlaceholder);

  static TextStyle get reviewBody =>
      _sans(14, FontWeight.w500, color: AppColors.textTertiary, height: 1.4);

  // ---- Labels ----
  /// All-caps eyebrow above a screen title.
  static TextStyle get eyebrow =>
      _sans(12, FontWeight.w700, color: AppColors.textPlaceholder, letterSpacing: 2);

  /// All-caps label inside a card ("COÛT EST.").
  static TextStyle get cardLabel =>
      _sans(12, FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 1.2);

  static TextStyle get cardLabelInfo =>
      _sans(12, FontWeight.w700, color: AppColors.infoLabel, letterSpacing: 1.2);

  /// Centred brand label inside recipe cards ("MACROS · PAR PORTION").
  static TextStyle get cardLabelBrand =>
      _sans(12, FontWeight.w800, color: AppColors.brand, letterSpacing: 1.4);

  /// Shopping category / account section heading.
  static TextStyle get groupLabel =>
      _sans(14, FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.1);

  static TextStyle get groupLabelSmall =>
      _sans(13, FontWeight.w800, color: AppColors.textTertiary, letterSpacing: 1.2);

  /// Day pill above a meal card.
  static TextStyle get dayPill =>
      _sans(12, FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.3);

  // ---- Interactive ----
  static TextStyle get primaryButton =>
      _sans(19, FontWeight.w800, color: AppColors.surface, letterSpacing: -0.3);

  static TextStyle get primaryButtonSmall => _sans(17, FontWeight.w800, color: AppColors.surface);

  static TextStyle get secondaryButton => _sans(15, FontWeight.w800);

  static TextStyle get segmentedLabel => _sans(17, FontWeight.w800);

  static TextStyle get tabLabel => _sans(14, FontWeight.w800, letterSpacing: -0.2);

  static TextStyle get link => _sans(16, FontWeight.w800, color: AppColors.brand);

  static TextStyle get input => _sans(19, FontWeight.w500);

  static TextStyle get searchInput => _sans(17, FontWeight.w500);

  static TextStyle get noteInput => _sans(15, FontWeight.w500);

  // ---- Cards & rows ----
  /// Title on an option card in a grid layout.
  static TextStyle get optionGrid => _sans(16, FontWeight.w800, letterSpacing: -0.3, height: 1.2);

  /// Title on an option card in a row layout.
  static TextStyle get optionRow => _sans(18, FontWeight.w800, letterSpacing: -0.3);

  /// Serif option row (language / country pickers).
  static TextStyle get optionRowSerif => _serif(20, FontWeight.w700, letterSpacing: -0.2);

  static TextStyle get languageName => _serif(20, FontWeight.w700, letterSpacing: -0.2);

  static TextStyle get dayCard => _sans(17, FontWeight.w800, letterSpacing: -0.3);

  static TextStyle get dayChip => _sans(14, FontWeight.w800);

  static TextStyle get mealTitle => _sans(17, FontWeight.w800, letterSpacing: -0.4, height: 1.2);

  static TextStyle get badge => _sans(14, FontWeight.w800, height: 1.2);

  static TextStyle get listItemTitle => _sans(17, FontWeight.w800, letterSpacing: -0.3);

  static TextStyle get ingredientName => _sans(16, FontWeight.w800);

  static TextStyle get ingredientQty =>
      _sans(15, FontWeight.w700, color: AppColors.textTertiary);

  static TextStyle get settingsRowTitle => _sans(16, FontWeight.w700);

  static TextStyle get settingsRowSub =>
      _sans(13.5, FontWeight.w500, color: AppColors.textPlaceholder);

  static TextStyle get chip => _sans(13, FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.5);

  static TextStyle get statValue => _sans(26, FontWeight.w700, letterSpacing: -0.5);

  static TextStyle get statLabel => _sans(13, FontWeight.w500, color: AppColors.textQuaternary);

  static TextStyle get amountLarge => _sans(22, FontWeight.w800, letterSpacing: -0.8);

  static TextStyle get amountMuted =>
      _sans(16, FontWeight.w700, color: AppColors.textDisabled, letterSpacing: -0.8);

  static TextStyle get reviewName => _sans(15, FontWeight.w800);

  static TextStyle get stars => _sans(13, FontWeight.w500, color: AppColors.star, letterSpacing: 1);
}
