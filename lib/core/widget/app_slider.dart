import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../util/haptics.dart';

/// The design's slider: a blue fill on a grey track, and a white thumb ringed in blue.
class AppSlider extends StatelessWidget {
  const AppSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;

  /// Snap interval, e.g. 0.5 for the budget and 0.1 for price per portion.
  final double step;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 7.h,
        activeTrackColor: AppColors.brand,
        inactiveTrackColor: AppColors.trackDark,
        thumbShape: _RingThumb(radius: 13.r),
        overlayShape: SliderComponentShape.noOverlay,
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: ((max - min) / step).round(),
        onChanged: (next) {
          if (next == value) return;
          Haptics.toggle();
          onChanged(next);
        },
      ),
    );
  }
}

/// White 26px thumb with a 2px brand ring and a soft shadow.
class _RingThumb extends SliderComponentShape {
  const _RingThumb({required this.radius});

  final double radius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    // Grows slightly while dragged, like the design's :active state.
    final r = radius * (1 + 0.12 * activationAnimation.value);
    canvas.drawCircle(
      center + const Offset(0, 2),
      r,
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(center, r, Paint()..color = AppColors.surface);
    canvas.drawCircle(
      center,
      r - 1,
      Paint()
        ..color = AppColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
