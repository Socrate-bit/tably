import 'package:flutter/material.dart';

/// Every colour used across the app: the warm Tably palette (orange on warm white).
/// Widgets must never hardcode a colour — they reference these tokens.
abstract final class AppColors {
  // Brand
  static const Color brand = Color(0xFFFF642E); // primary orange
  static const Color brandDark = Color(0xFFE84F1C); // pressed / links
  static const Color brandDarker = Color(0xFFB83D12);
  static const Color brandLight = Color(0xFFFF8A3D); // tangerine, gradient head
  static const Color brandDeep = Color(0xFFFF3D20); // gradient tail
  static const Color brandSoft = Color(0xFFFFF1E7); // cream tinted surfaces
  static const Color brandSoftBorder = Color(0xFFFFD9C3);
  static const Color brandSoftInk = Color(0xFFA2532F);
  static const Color brandChip = Color(0xFFFFD9C3);

  // Ink / text
  static const Color ink = Color(0xFF171923); // primary text (INK)
  static const Color inkStrong = Color(0xFF221D1F);
  static const Color inkBody = Color(0xFF4A3F3A);
  static const Color inkMuted = Color(0xFF5E524C);
  static const Color textSecondary = Color(0xFF7D6F68);
  static const Color textTertiary = Color(0xFF8E7F78);
  static const Color textQuaternary = Color(0xFF9B8C84);
  static const Color textPlaceholder = Color(0xFFA69790);
  static const Color textDisabled = Color(0xFFBCAEA6);
  static const Color chevron = Color(0xFFCDBFB6);
  static const Color emptyStateIcon = Color(0xFFE2D4CB);

  // Surfaces
  static const Color scaffold = Color(0xFFFFFCF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFFFFDFA);
  static const Color surfaceTinted = Color(0xFFFFFAF5);
  static const Color surfaceMuted = Color(0xFFFFF6EF);
  static const Color fill = Color(0xFFFBEFE7); // neutral filled controls
  static const Color track = Color(0xFFF7E6DA); // progress / slider track
  static const Color trackDark = Color(0xFFF2DDCF);
  static const Color neutralBar = Color(0xFFE8D3C5);
  static const Color photoPlaceholder = Color(0xFFFBEEE5); // gradient head behind a missing photo

  // Borders
  static const Color border = Color(0xFFF4DED1);
  static const Color borderSoft = Color(0xFFF7E6DB);
  static const Color divider = Color(0xFFF8EAE0);
  static const Color toggleOff = Color(0xFFEBDACE);

  // Accents
  static const Color info = Color(0xFFFFE9DC); // shopping-list card
  static const Color infoInk = Color(0xFFB83D12);
  static const Color infoLabel = Color(0xFFFF642E);
  static const Color infoTrack = Color(0xFFFFF6F0);
  static const Color star = Color(0xFFF2B32C);
  static const Color ratingStar = Color(0xFFFF642E); // App Store-style prompt
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
  static const Color creatorScrim = Color(0xD1171923); // .82 ink

  // Scrims
  static const Color scrim = Color(0x57171923); // .34 opacity sheet backdrop
  static const Color scrimModal = Color(0x5212120E); // .32 opacity rating modal
}
