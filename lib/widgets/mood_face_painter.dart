import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mood.dart';

/// Paints a stylized face for a given [Mood] using only canvas primitives:
/// drawCircle, drawArc, drawPath, drawLine.
/// No emoji, no icon fonts, no images.
class MoodFacePainter extends CustomPainter {
  final Mood mood;
  final double expression; // 0.0 -> 1.0 used by tap animation (scale of features)

  MoodFacePainter({required this.mood, this.expression = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    // --- Face circle ---
    final facePaint = Paint()
      ..color = mood.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    // Subtle inner shadow ring for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 1, shadowPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, outlinePaint);

    // --- Eyes ---
    _drawEyes(canvas, center, radius);

    // --- Eyebrows (mood-specific) ---
    _drawEyebrows(canvas, center, radius);

    // --- Mouth (mood-specific) ---
    _drawMouth(canvas, center, radius);

    // --- Extra cheek blush on happy/good ---
    if (mood == Mood.happy || mood == Mood.good) {
      _drawBlush(canvas, center, radius);
    }

    // --- Tear on sad ---
    if (mood == Mood.sad) {
      _drawTear(canvas, center, radius);
    }
  }

  void _drawEyes(Canvas canvas, Offset c, double r) {
    final eyePaint = Paint()..color = Colors.black87;

    final eyeOffsetX = r * 0.38;
    final eyeOffsetY = r * 0.18;
    final eyeRadius = r * 0.09 * expression;

    final left = Offset(c.dx - eyeOffsetX, c.dy - eyeOffsetY);
    final right = Offset(c.dx + eyeOffsetX, c.dy - eyeOffsetY);

    if (mood == Mood.happy) {
      // Happy eyes: upward arcs (^  ^)
      final strokePaint = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08
        ..strokeCap = StrokeCap.round;
      final w = r * 0.22;
      _drawArcAt(canvas, left, w, math.pi, math.pi, strokePaint);
      _drawArcAt(canvas, right, w, math.pi, math.pi, strokePaint);
    } else {
      canvas.drawCircle(left, eyeRadius, eyePaint);
      canvas.drawCircle(right, eyeRadius, eyePaint);
    }
  }

  void _drawEyebrows(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;

    final eyeOffsetX = r * 0.38;
    final browY = c.dy - r * 0.38;
    final browLen = r * 0.28;

    switch (mood) {
      case Mood.angry:
        // Angled inward and down (\  /)
        canvas.drawLine(
          Offset(c.dx - eyeOffsetX - browLen / 2, browY - r * 0.05),
          Offset(c.dx - eyeOffsetX + browLen / 2, browY + r * 0.10),
          paint,
        );
        canvas.drawLine(
          Offset(c.dx + eyeOffsetX - browLen / 2, browY + r * 0.10),
          Offset(c.dx + eyeOffsetX + browLen / 2, browY - r * 0.05),
          paint,
        );
        break;
      case Mood.sad:
        // Outer ends down (/  \)
        canvas.drawLine(
          Offset(c.dx - eyeOffsetX - browLen / 2, browY + r * 0.08),
          Offset(c.dx - eyeOffsetX + browLen / 2, browY - r * 0.04),
          paint,
        );
        canvas.drawLine(
          Offset(c.dx + eyeOffsetX - browLen / 2, browY - r * 0.04),
          Offset(c.dx + eyeOffsetX + browLen / 2, browY + r * 0.08),
          paint,
        );
        break;
      case Mood.neutral:
        // Flat (—  —)
        canvas.drawLine(
          Offset(c.dx - eyeOffsetX - browLen / 2, browY),
          Offset(c.dx - eyeOffsetX + browLen / 2, browY),
          paint,
        );
        canvas.drawLine(
          Offset(c.dx + eyeOffsetX - browLen / 2, browY),
          Offset(c.dx + eyeOffsetX + browLen / 2, browY),
          paint,
        );
        break;
      case Mood.good:
      case Mood.happy:
        // Gentle upward curve
        final path = Path()
          ..moveTo(c.dx - eyeOffsetX - browLen / 2, browY + r * 0.03)
          ..quadraticBezierTo(
            c.dx - eyeOffsetX,
            browY - r * 0.08,
            c.dx - eyeOffsetX + browLen / 2,
            browY + r * 0.03,
          );
        final path2 = Path()
          ..moveTo(c.dx + eyeOffsetX - browLen / 2, browY + r * 0.03)
          ..quadraticBezierTo(
            c.dx + eyeOffsetX,
            browY - r * 0.08,
            c.dx + eyeOffsetX + browLen / 2,
            browY + r * 0.03,
          );
        canvas.drawPath(path, paint);
        canvas.drawPath(path2, paint);
        break;
    }
  }

  void _drawMouth(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..strokeCap = StrokeCap.round;

    final mouthY = c.dy + r * 0.25;
    final mouthW = r * 0.7;

    switch (mood) {
      case Mood.happy:
        // Big open smile (filled)
        final fill = Paint()..color = Colors.black87;
        final rect = Rect.fromCenter(
          center: Offset(c.dx, mouthY),
          width: mouthW,
          height: r * 0.6,
        );
        canvas.drawArc(rect, 0, math.pi, false, fill);
        // Tongue hint
        final tonguePaint = Paint()..color = const Color(0xFFEF6B7E);
        final tongueRect = Rect.fromCenter(
          center: Offset(c.dx, mouthY + r * 0.1),
          width: mouthW * 0.6,
          height: r * 0.3,
        );
        canvas.drawArc(tongueRect, 0, math.pi, false, tonguePaint);
        break;
      case Mood.good:
        // Curved smile, not as wide
        final rect = Rect.fromCenter(
          center: Offset(c.dx, mouthY - r * 0.05),
          width: mouthW * 0.85,
          height: r * 0.4,
        );
        canvas.drawArc(rect, 0, math.pi, false, paint);
        break;
      case Mood.neutral:
        // Straight line
        canvas.drawLine(
          Offset(c.dx - mouthW / 2, mouthY),
          Offset(c.dx + mouthW / 2, mouthY),
          paint,
        );
        break;
      case Mood.sad:
        // Frown — inverted arc
        final rect = Rect.fromCenter(
          center: Offset(c.dx, mouthY + r * 0.15),
          width: mouthW * 0.85,
          height: r * 0.4,
        );
        canvas.drawArc(rect, math.pi, math.pi, false, paint);
        break;
      case Mood.angry:
        // Wavy/clenched line via path
        final path = Path()..moveTo(c.dx - mouthW / 2, mouthY);
        const segments = 4;
        for (int i = 1; i <= segments; i++) {
          final x = c.dx - mouthW / 2 + (mouthW / segments) * i;
          final y = mouthY + (i.isEven ? -r * 0.07 : r * 0.07);
          path.lineTo(x, y);
        }
        canvas.drawPath(path, paint);
        break;
    }
  }

  void _drawBlush(Canvas canvas, Offset c, double r) {
    final paint = Paint()..color = Colors.pinkAccent.withValues(alpha: 0.35);
    canvas.drawCircle(
      Offset(c.dx - r * 0.5, c.dy + r * 0.1),
      r * 0.13,
      paint,
    );
    canvas.drawCircle(
      Offset(c.dx + r * 0.5, c.dy + r * 0.1),
      r * 0.13,
      paint,
    );
  }

  void _drawTear(Canvas canvas, Offset c, double r) {
    final paint = Paint()..color = const Color(0xFF4FC3F7);
    final path = Path()
      ..moveTo(c.dx - r * 0.38, c.dy - r * 0.05)
      ..quadraticBezierTo(
        c.dx - r * 0.30,
        c.dy + r * 0.10,
        c.dx - r * 0.34,
        c.dy + r * 0.20,
      )
      ..quadraticBezierTo(
        c.dx - r * 0.42,
        c.dy + r * 0.10,
        c.dx - r * 0.38,
        c.dy - r * 0.05,
      )
      ..close();
    canvas.drawPath(path, paint);

    final outline = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, outline);
  }

  void _drawArcAt(
    Canvas canvas,
    Offset center,
    double width,
    double startAngle,
    double sweep,
    Paint paint,
  ) {
    final rect = Rect.fromCenter(center: center, width: width, height: width);
    canvas.drawArc(rect, startAngle, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant MoodFacePainter old) =>
      old.mood != mood || old.expression != expression;
}
