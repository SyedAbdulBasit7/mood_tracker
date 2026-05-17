import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mood.dart';

/// A full-screen, non-interactive overlay that sprays ~14 mood-themed
/// particles from [origin] whenever [triggerKey] changes. Each mood has
/// its own shape, all drawn with CustomPainter primitives:
///
///   * Happy   → heart
///   * Good    → 4-point sparkle
///   * Neutral → dot
///   * Sad     → teardrop
///   * Angry   → jagged 5-point spark
///
/// Particles launch upward in a 140° spread with randomized speed/spin
/// and then fall under gravity (px/s²). Faded out over the final 30%
/// of their life so they vanish before hitting the bottom of the screen.
class MoodParticleBurst extends StatefulWidget {
  final Offset? origin;
  final Mood? mood;
  final Object? triggerKey;

  const MoodParticleBurst({
    super.key,
    required this.origin,
    required this.mood,
    required this.triggerKey,
  });

  @override
  State<MoodParticleBurst> createState() => _MoodParticleBurstState();
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double startRotation;
  final double spin;
  final double startDelay; // 0..0.1 of controller life — feels less robotic

  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.startRotation,
    required this.spin,
    required this.startDelay,
  });
}

class _MoodParticleBurstState extends State<MoodParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_Particle> _particles = const [];
  final _rng = math.Random();

  static const _count = 14;
  static const _durationMs = 950;
  static const _gravity = 850.0; // px/s²

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _durationMs),
    );
  }

  @override
  void didUpdateWidget(covariant MoodParticleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerKey != null &&
        widget.triggerKey != oldWidget.triggerKey &&
        widget.origin != null &&
        widget.mood != null) {
      _particles = _spawn();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Particle> _spawn() {
    return List<_Particle>.generate(_count, (_) {
      // Flutter Y+ is down → bias upward by sampling angles in [200°, 340°].
      final degrees = 200 + _rng.nextDouble() * 140;
      final angle = degrees * math.pi / 180;
      final speed = 260 + _rng.nextDouble() * 240;
      final size = 9 + _rng.nextDouble() * 9;
      final rot = _rng.nextDouble() * math.pi * 2;
      final spin = (_rng.nextDouble() - 0.5) * math.pi * 4;
      final delay = _rng.nextDouble() * 0.10;
      return _Particle(
        angle: angle,
        speed: speed,
        size: size,
        startRotation: rot,
        spin: spin,
        startDelay: delay,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isDismissed ||
              widget.origin == null ||
              widget.mood == null ||
              _particles.isEmpty) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            size: Size.infinite,
            painter: _BurstPainter(
              origin: widget.origin!,
              mood: widget.mood!,
              particles: _particles,
              progress: _controller.value,
              gravity: _gravity,
              durationSec: _durationMs / 1000.0,
            ),
          );
        },
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final Offset origin;
  final Mood mood;
  final List<_Particle> particles;
  final double progress;
  final double gravity;
  final double durationSec;

  _BurstPainter({
    required this.origin,
    required this.mood,
    required this.particles,
    required this.progress,
    required this.gravity,
    required this.durationSec,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final accent = mood.accent;

    for (final p in particles) {
      // Per-particle life, shifted by startDelay so the burst staggers.
      final pt =
          ((progress - p.startDelay) / (1 - p.startDelay)).clamp(0.0, 1.0);
      if (pt <= 0) continue;

      final t = pt * durationSec;
      final dx = p.speed * math.cos(p.angle) * t;
      final dy = p.speed * math.sin(p.angle) * t + 0.5 * gravity * t * t;
      final pos = Offset(origin.dx + dx, origin.dy + dy);

      // Opacity: full to 70% of life, then linear fade to 0.
      final alpha = pt < 0.7
          ? 1.0
          : (1 - (pt - 0.7) / 0.3).clamp(0.0, 1.0);

      // Light shrink toward the end so they "dissolve."
      final scale = 1.0 - 0.25 * pt;
      final rotation = p.startRotation + p.spin * t;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rotation);
      canvas.scale(scale);
      _drawShape(canvas, p.size, accent.withValues(alpha: alpha));
      canvas.restore();
    }
  }

  void _drawShape(Canvas canvas, double s, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    switch (mood) {
      case Mood.happy:
        _heart(canvas, s, paint);
        break;
      case Mood.good:
        _sparkle(canvas, s, paint);
        break;
      case Mood.neutral:
        canvas.drawCircle(Offset.zero, s * 0.35, paint);
        break;
      case Mood.sad:
        _teardrop(canvas, s, paint);
        break;
      case Mood.angry:
        _spark(canvas, s, paint);
        break;
    }
  }

  void _heart(Canvas canvas, double s, Paint p) {
    final h = s * 0.9;
    final path = Path()
      ..moveTo(0, h * 0.30)
      ..cubicTo(-h * 0.70, -h * 0.15, -h * 0.50, -h * 0.65, 0, -h * 0.25)
      ..cubicTo(h * 0.50, -h * 0.65, h * 0.70, -h * 0.15, 0, h * 0.30)
      ..close();
    canvas.drawPath(path, p);
  }

  void _sparkle(Canvas canvas, double s, Paint p) {
    final long = s * 0.55;
    final short = s * 0.12;
    canvas.drawPath(
      Path()
        ..moveTo(0, -long)
        ..lineTo(short, 0)
        ..lineTo(0, long)
        ..lineTo(-short, 0)
        ..close(),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-long, 0)
        ..lineTo(0, short)
        ..lineTo(long, 0)
        ..lineTo(0, -short)
        ..close(),
      p,
    );
  }

  void _teardrop(Canvas canvas, double s, Paint p) {
    final h = s * 0.55;
    final w = s * 0.32;
    final path = Path()
      ..moveTo(0, -h)
      ..quadraticBezierTo(w, 0, 0, h * 0.7)
      ..quadraticBezierTo(-w, 0, 0, -h)
      ..close();
    canvas.drawPath(path, p);
  }

  void _spark(Canvas canvas, double s, Paint p) {
    final outer = s * 0.55;
    final inner = s * 0.22;
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.progress != progress ||
      old.particles != particles ||
      old.mood != mood;
}
