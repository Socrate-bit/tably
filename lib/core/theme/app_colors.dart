import 'package:flutter/material.dart';

/// Every colour used across the app, taken verbatim from the Tably design.
/// Widgets must never hardcode a colour — they reference these tokens.
abstract final class AppColors {
  // Brand
  static const Color brand = Color(0xFF2E6BE6); // primary blue (G)
  static const Color brandDark = Color(0xFF1F4FB8); // pressed / links (GD)
  static const Color brandDarker = Color(0xFF1B4497);
  static const Color brandLight = Color(0xFF5B95F5); // gradient tail
  static const Color brandSoft = Color(0xFFE8F0FE); // tinted surfaces
  static const Color brandSoftBorder = Color(0xFFCBDCF9);
  static const Color brandSoftInk = Color(0xFF3A5A94);
  static const Color brandChip = Color(0xFFD3E3FD);

  // Ink / text
  static const Color ink = Color(0xFF141B29); // primary text (INK)
  static const Color inkStrong = Color(0xFF1B2333);
  static const Color inkBody = Color(0xFF3A4354);
  static const Color inkMuted = Color(0xFF4E5868);
  static const Color textSecondary = Color(0xFF6B7688);
  static const Color textTertiary = Color(0xFF7C879A);
  static const Color textQuaternary = Color(0xFF8792A3);
  static const Color textPlaceholder = Color(0xFF8C97A8);
  static const Color textDisabled = Color(0xFFA6B0BF);
  static const Color chevron = Color(0xFFB4BECC);
  static const Color emptyStateIcon = Color(0xFFC6CEDA);

  // Surfaces
  static const Color scaffold = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFFAFCFE);
  static const Color surfaceTinted = Color(0xFFF9FBFE);
  static const Color surfaceMuted = Color(0xFFF2F5FA);
  static const Color fill = Color(0xFFEDF1F7); // neutral filled controls
  static const Color track = Color(0xFFE3E8F0); // progress / slider track
  static const Color trackDark = Color(0xFFDCE3EE);
  static const Color neutralBar = Color(0xFFD4DCE8);
  static const Color photoPlaceholder = Color(0xFFEEF2F8); // gradient head behind a missing photo

  // Borders
  static const Color border = Color(0xFFE6EBF3);
  static const Color borderSoft = Color(0xFFE9EEF6);
  static const Color divider = Color(0xFFEDF1F7);
  static const Color toggleOff = Color(0xFFD9E1EC);

  // Accents
  static const Color info = Color(0xFFDBEEFB); // shopping-list card
  static const Color infoInk = Color(0xFF2C6FA0);
  static const Color infoLabel = Color(0xFF4A85B0);
  static const Color infoTrack = Color(0xFFEAF4FC);
  static const Color star = Color(0xFFF2B32C);
  static const Color ratingStar = Color(0xFF2F6FDB); // App Store-style prompt
  static const Color danger = Color(0xFFE0503F); // protein macro + destructive
  static const Color carbs = Color(0xFFE39A2B);

  // Meal badges
  static const Color badgeQuickBg = Color(0xFFE4DAFA);
  static const Color badgeQuickInk = Color(0xFF5E43A8);
  static const Color badgeProteinBg = Color(0xFFFBC6D4);
  static const Color badgeProteinInk = Color(0xFFB02E5C);
  static const Color badgeIndulgentBg = Color(0xFFFDE7C4);
  static const Color badgeIndulgentInk = Color(0xFF96601A);

  // Creator credit over a recipe photo
  static const Color creatorScrim = Color(0xD1141B29); // .82 ink

  // Scrims
  static const Color scrim = Color(0x57141B29); // .34 opacity sheet backdrop
  static const Color scrimModal = Color(0x5212120E); // .32 opacity rating modal
}
