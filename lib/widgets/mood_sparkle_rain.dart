import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mood.dart';

/// A full-screen, non-interactive overlay that rains ~50 sparkles in the
/// given [mood]'s accent color whenever [triggerKey] changes. Sparkles
/// spawn above the top of the screen at random x positions, fall under
/// gravity with a slight sideways drift, and fade out in the last 30%
/// of their life. Designed to fire when the user enters "review" mode
/// for a past entry — distinct from the picker's point-origin burst.
class MoodSparkleRain extends StatefulWidget {
  final Mood? mood;
  final Object? triggerKey;

  const MoodSparkleRain({
    super.key,
    required this.mood,
    required this.triggerKey,
  });

  @override
  State<MoodSparkleRain> createState() => _MoodSparkleRainState();
}

class _Sparkle {
  final double startX;
  final double startY;
  final double vx;
  final double vy;
  final double size;
  final double startRotation;
  final double spinRate;
  final double startDelay; // 0..0.35 of total life
  final double opacity;

  const _Sparkle({
    required this.startX,
    required this.startY,
    required this.vx,
    required this.vy,
    required this.size,
    required this.startRotation,
    required this.spinRate,
    required this.startDelay,
    required this.opacity,
  });
}

class _MoodSparkleRainState extends State<MoodSparkleRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_Sparkle> _sparkles = const [];
  final _rng = math.Random();
  Size _lastSize = Size.zero;

  static const _count = 50;
  static const _durationMs = 2400;
  static const _gravity = 380.0; // px/s² — softer than the picker burst

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _durationMs),
    );
  }

  @override
  void didUpdateWidget(covariant MoodSparkleRain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerKey != null &&
        widget.triggerKey != oldWidget.triggerKey &&
        widget.mood != null) {
      _sparkles = _spawn(_lastSize);
      _controller.forward(from: 0);
    }
  }

  List<_Sparkle> _spawn(Size size) {
    if (size.width <= 0) return const [];
    return List<_Sparkle>.generate(_count, (_) {
      return _Sparkle(
        startX: _rng.nextDouble() * size.width,
        // Spawn above the viewport, spread vertically so they don't all
        // appear at once.
        startY: -40 - _rng.nextDouble() * 220,
        vx: (_rng.nextDouble() - 0.5) * 80,
        vy: 60 + _rng.nextDouble() * 140,
        size: 7 + _rng.nextDouble() * 10,
        startRotation: _rng.nextDouble() * math.pi * 2,
        spinRate: (_rng.nextDouble() - 0.5) * math.pi * 3,
        startDelay: _rng.nextDouble() * 0.35,
        opacity: 0.65 + _rng.nextDouble() * 0.35,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isDismissed ||
                  widget.mood == null ||
                  _sparkles.isEmpty) {
                return const SizedBox.shrink();
              }
              return CustomPaint(
                size: Size.infinite,
                painter: _RainPainter(
                  color: widget.mood!.accent,
                  sparkles: _sparkles,
                  progress: _controller.value,
                  gravity: _gravity,
                  durationSec: _durationMs / 1000.0,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  final Color color;
  final List<_Sparkle> sparkles;
  final double progress;
  final double gravity;
  final double durationSec;

  _RainPainter({
    required this.color,
    required this.sparkles,
    required this.progress,
    required this.gravity,
    required this.durationSec,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final pt =
          ((progress - s.startDelay) / (1 - s.startDelay)).clamp(0.0, 1.0);
      if (pt <= 0) continue;

      final t = pt * durationSec;
      final x = s.startX + s.vx * t;
      final y = s.startY + s.vy * t + 0.5 * gravity * t * t;

      // Cheap off-screen cull.
      if (y > size.height + 40 || x < -40 || x > size.width + 40) continue;

      // Opacity envelope: fade in over first 10%, hold to 70%, fade out by end.
      final double envelope;
      if (pt < 0.10) {
        envelope = pt / 0.10;
      } else if (pt < 0.70) {
        envelope = 1.0;
      } else {
        envelope = (1 - (pt - 0.70) / 0.30).clamp(0.0, 1.0);
      }
      final alpha = (envelope * s.opacity).clamp(0.0, 1.0);
      if (alpha <= 0) continue;

      final rotation = s.startRotation + s.spinRate * t;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      _drawSparkle(canvas, s.size, color.withValues(alpha: alpha));
      canvas.restore();
    }
  }

  void _drawSparkle(Canvas canvas, double s, Color color) {
    final long = s * 0.55;
    final short = s * 0.12;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(0, -long)
        ..lineTo(short, 0)
        ..lineTo(0, long)
        ..lineTo(-short, 0)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-long, 0)
        ..lineTo(0, short)
        ..lineTo(long, 0)
        ..lineTo(0, -short)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.sparkles != sparkles;
}
