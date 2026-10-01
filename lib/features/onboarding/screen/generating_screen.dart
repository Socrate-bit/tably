import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/app_logo.dart';
import '../../../core/widget/primary_button.dart';
import '../../../core/widget/progress_bar.dart';
import '../../../core/widget/surface_card.dart';
import '../../../l10n/app_localizations.dart';

/// The "on prépare ta semaine" screen: an orbiting ingredient ring above a
/// checklist that ticks off as the recipes are searched, checked and saved.
class GeneratingScreen extends StatefulWidget {
  const GeneratingScreen({
    super.key,
    required this.displayName,
    required this.generationStep,
    this.failed = false,
    this.onRetry,
  });

  final String displayName;

  /// 0–3; drives the checklist and the progress bar.
  final int generationStep;

  /// The build failed: the ready line becomes an error with a retry button.
  final bool failed;
  final VoidCallback? onRetry;

  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen> with TickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  static const _orbitIcons = ['🥑', '🍅', '🍋', '🫑', '🥒', '🥬', '🌽', '🍆', '🧄'];

  @override
  void dispose() {
    _orbit.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tasks = [
      l10n.generatingTaskMatch,
      l10n.generatingTaskOrganise,
      l10n.generatingTaskShopping,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 48.h, 24.w, 26.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.generatingTitle(widget.displayName),
            style: AppTextStyles.h1.copyWith(height: 1.15),
          ),
          Expanded(child: _orbitRing),
          Padding(
            padding: EdgeInsets.only(bottom: 18.h),
            child: ProgressBar(value: widget.generationStep / 3, animate: true),
          ),
          SurfaceCard(
            radius: 24.r,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
            child: Column(
              children: [
                for (final (index, task) in tasks.indexed) ...[
                  _TaskRow(
                    label: task,
                    done: widget.generationStep > index,
                    active: widget.generationStep == index,
                    pulse: _pulse,
                  ),
                  if (index < tasks.length - 1) SizedBox(height: 16.h),
                ],
              ],
            ),
          ),
          SizedBox(height: 14.h),
          if (widget.failed) ...[
            Text(
              l10n.generatingFailed,
              textAlign: TextAlign.center,
              style: AppTextStyles.metaSmall.copyWith(color: AppColors.danger),
            ),
            SizedBox(height: 12.h),
            PrimaryButton(label: l10n.actionRetry, onPressed: widget.onRetry),
          ] else
            // Kept in the layout while building so nothing shifts when it appears.
            Opacity(
              opacity: widget.generationStep >= 3 ? 1 : 0,
              child: Text(
                l10n.generatingReady,
                textAlign: TextAlign.center,
                style: AppTextStyles.metaSmall.copyWith(color: AppColors.textDisabled),
              ),
            ),
        ],
      ),
    );
  }

  /// The Tably mark pulsing at the centre of a slowly rotating ingredient ring.
  Widget get _orbitRing => ConstrainedBox(
        constraints: BoxConstraints(minHeight: 250.h),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _orbit,
              builder: (context, _) => Transform.rotate(
                angle: _orbit.value * 2 * pi,
                child: SizedBox(
                  width: 236.r,
                  height: 236.r,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final (index, icon) in _orbitIcons.indexed)
                        _OrbitIcon(
                          icon: icon,
                          angle: index / _orbitIcons.length * 2 * pi - pi / 2,
                          radius: 118.r,
                          counterRotation: -_orbit.value * 2 * pi,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.07).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: AppWordmark(height: 46.h),
            ),
          ],
        ),
      );
}

/// One ingredient on the ring, kept upright as the ring turns.
class _OrbitIcon extends StatelessWidget {
  const _OrbitIcon({
    required this.icon,
    required this.angle,
    required this.radius,
    required this.counterRotation,
  });

  final String icon;
  final double angle;
  final double radius;
  final double counterRotation;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(cos(angle) * radius, sin(angle) * radius),
      child: Transform.rotate(
        angle: counterRotation,
        child: Text(icon, style: AppTextStyles.emojiIcon.copyWith(fontSize: 34.sp)),
      ),
    );
  }
}

/// A checklist line: pending, active (pulsing ring) or done (filled tick).
class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.label,
    required this.done,
    required this.active,
    required this.pulse,
  });

  final String label;
  final bool done;
  final bool active;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 26.r,
      height: 26.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.brand : Colors.transparent,
        border: done
            ? null
            : Border.all(color: active ? AppColors.brand : AppColors.trackDark, width: 2),
      ),
      child: Text(
        done ? '✓' : '',
        style: AppTextStyles.emojiIcon.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.surface),
      ),
    );

    return Row(
      children: [
        active
            ? ScaleTransition(
                scale: Tween<double>(begin: 1, end: 1.07)
                    .animate(CurvedAnimation(parent: pulse, curve: Curves.easeInOut)),
                child: dot,
              )
            : dot,
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.subtitleTight.copyWith(
              height: 1.25,
              fontWeight: done || active ? FontWeight.w800 : FontWeight.w500,
              color: done || active ? AppColors.ink : AppColors.textQuaternary,
            ),
          ),
        ),
      ],
    );
  }
}
