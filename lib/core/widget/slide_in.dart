import 'package:flutter/material.dart';

/// The design's `tb-slide`: content fades in while rising 14px. Wrap a child
/// with a new [key] to replay it.
class SlideIn extends StatelessWidget {
  const SlideIn({super.key, required this.child});

  final Widget child;

  static const duration = Duration(milliseconds: 340);
  static const curve = Cubic(0.22, 0.7, 0.3, 1);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
