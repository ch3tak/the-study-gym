import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A circular progress ring used for chapter mastery in the Skill Map, and
/// for the Board-Readiness-style gauge on Today. Color follows mastery
/// banding so it never depends on a legend.
class MasteryRing extends StatelessWidget {
  const MasteryRing({
    super.key,
    required this.progress,
    this.size = 56,
    this.strokeWidth = 6,
    this.child,
    this.trackColor,
    this.animate = true,
  });

  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final Widget? child;
  final Color? trackColor;
  final bool animate;

  Color _colorFor(double p) {
    if (p >= 0.8) return AppColors.mastered;
    if (p >= 0.5) return AppColors.learning;
    if (p > 0) return AppColors.weak;
    return AppColors.notStarted;
  }

  @override
  Widget build(BuildContext context) {
    final target = progress.clamp(0.0, 1.0);
    final color = _colorFor(target);

    final ring = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: animate ? const Duration(milliseconds: 900) : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return CustomPaint(
          size: Size(size, size),
          painter: _RingPainter(
            progress: value,
            color: color,
            trackColor: trackColor ?? AppColors.border,
            strokeWidth: strokeWidth,
          ),
        );
      },
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [ring, if (child != null) child!],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
