import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared spacing and radius values from the design. Screen-relative via
/// ScreenUtil so the layout holds on every device size.
abstract final class AppDimens {
  /// The design frame these values were measured against.
  static const double designWidth = 402;
  static const double designHeight = 860;

  // Horizontal page padding
  static double get pageH => 20.w;
  static double get pageHWide => 24.w;
  static double get pageHNarrow => 14.w;

  // Radii
  static double get radiusCard => 22.r;
  static double get radiusCardLarge => 24.r;
  static double get radiusCardSmall => 20.r;
  static double get radiusTile => 18.r;
  static double get radiusChip => 20.r;
  static double get radiusPill => 34.r;
  static double get radiusSheet => 30.r;

  // Controls
  static double get circleButton => 42.r;
  static double get circleButtonLarge => 44.r;
  static double get counterButton => 56.r;
  static double get counterButtonSmall => 46.r;
  static double get fab => 90.r;
  static double get trackHeight => 7.h;

  /// Clearance under scrollable content for the floating glass tab bar.
  static double get tabBarInset => 104.h;

  // Common gaps
  static double get gapXs => 4.h;
  static double get gapS => 8.h;
  static double get gapM => 13.h;
  static double get gapL => 18.h;
  static double get gapXl => 26.h;
}
