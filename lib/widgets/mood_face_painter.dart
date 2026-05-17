import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mood.dart';

/// Paints a stylized face for [mood] using only canvas primitives —
/// drawCircle, drawArc, drawPath, drawLine. No emoji, no icon fonts.
///
/// When [previousMood] is provided and [revealProgress] < 1.0, the face
/// color cross-fades from the previous accent to the new one, and each
/// feature (eyes → brows → mouth → extras) reveals in a staggered sequence
/// using PathMetric extraction, scaleY, and opacity.
class MoodFacePainter extends CustomPainter {
  final Mood mood;
  final Mood? previousMood;
  final double revealProgress;

  MoodFacePainter({
    required this.mood,
    this.previousMood,
    this.revealProgress = 1.0,
  });

  double _stagger(double start, double end, Curve curve) {
    final t = ((revealProgress - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  Color get _faceColor {
    if (previousMood == null || revealProgress >= 1.0) return mood.accent;
    return Color.lerp(previousMood!.accent, mood.accent, revealProgress) ??
        mood.accent;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    // --- Face circle (color lerps continuously) ---
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _faceColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.06
        ..strokeCap = StrokeCap.round,
    );

    final eyesT = _stagger(0.00, 0.35, Curves.easeOutCubic);
    final browsT = _stagger(0.20, 0.55, Curves.easeOutCubic);
    final mouthT = _stagger(0.40, 0.85, Curves.easeOutBack);
    final extrasT = _stagger(0.70, 1.00, Curves.easeOutCubic);

    if (eyesT > 0) _drawEyes(canvas, center, radius, eyesT);
    if (browsT > 0) _drawEyebrows(canvas, center, radius, browsT);
    if (mouthT > 0) _drawMouth(canvas, center, radius, mouthT);

    if (extrasT > 0) {
      if (mood == Mood.happy || mood == Mood.good) {
        _drawBlush(canvas, center, radius, extrasT);
      }
      if (mood == Mood.sad) {
        _drawTear(canvas, center, radius, extrasT);
      }
    }
  }

  void _drawEyes(Canvas canvas, Offset c, double r, double t) {
    final eyeOffsetX = r * 0.38;
    final eyeOffsetY = r * 0.18;

    final left = Offset(c.dx - eyeOffsetX, c.dy - eyeOffsetY);
    final right = Offset(c.dx + eyeOffsetX, c.dy - eyeOffsetY);

    if (mood == Mood.happy) {
      // Happy eyes: upward arcs (^  ^) — path-extract for grow-in
      final w = r * 0.22;
      final stroke = Paint()
        ..color = Colors.black87.withValues(alpha: t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08
        ..strokeCap = StrokeCap.round;
      _drawArcGrow(canvas, left, w, math.pi, math.pi, t, stroke);
      _drawArcGrow(canvas, right, w, math.pi, math.pi, t, stroke);
    } else {
      final eyeRadius = r * 0.09;
      final eyePaint = Paint()..color = Colors.black87.withValues(alpha: t);
      _drawEyelidOpen(canvas, left, eyeRadius, t, eyePaint);
      _drawEyelidOpen(canvas, right, eyeRadius, t, eyePaint);
    }
  }

  void _drawEyelidOpen(Canvas canvas, Offset c, double r, double t, Paint p) {
    final scaleY = (0.1 + 0.9 * t).clamp(0.1, 1.0);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1.0, scaleY);
    canvas.drawCircle(Offset.zero, r, p);
    canvas.restore();
  }

  void _drawArcGrow(
    Canvas canvas,
    Offset center,
    double width,
    double start,
    double sweep,
    double t,
    Paint paint,
  ) {
    final rect = Rect.fromCenter(center: center, width: width, height: width);
    final path = Path()..addArc(rect, start, sweep * t);
    canvas.drawPath(path, paint);
  }

  void _drawEyebrows(Canvas canvas, Offset c, double r, double t) {
    final paint = Paint()
      ..color = Colors.black87.withValues(alpha: t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;

    final eyeOffsetX = r * 0.38;
    final browY = c.dy - r * 0.38;
    final browLen = r * 0.28;

    final leftPath = Path();
    final rightPath = Path();

    switch (mood) {
      case Mood.angry:
        leftPath
          ..moveTo(c.dx - eyeOffsetX - browLen / 2, browY - r * 0.05)
          ..lineTo(c.dx - eyeOffsetX + browLen / 2, browY + r * 0.10);
        rightPath
          ..moveTo(c.dx + eyeOffsetX - browLen / 2, browY + r * 0.10)
          ..lineTo(c.dx + eyeOffsetX + browLen / 2, browY - r * 0.05);
        break;
      case Mood.sad:
        leftPath
          ..moveTo(c.dx - eyeOffsetX - browLen / 2, browY + r * 0.08)
          ..lineTo(c.dx - eyeOffsetX + browLen / 2, browY - r * 0.04);
        rightPath
          ..moveTo(c.dx + eyeOffsetX - browLen / 2, browY - r * 0.04)
          ..lineTo(c.dx + eyeOffsetX + browLen / 2, browY + r * 0.08);
        break;
      case Mood.neutral:
        leftPath
          ..moveTo(c.dx - eyeOffsetX - browLen / 2, browY)
          ..lineTo(c.dx - eyeOffsetX + browLen / 2, browY);
        rightPath
          ..moveTo(c.dx + eyeOffsetX - browLen / 2, browY)
          ..lineTo(c.dx + eyeOffsetX + browLen / 2, browY);
        break;
      case Mood.good:
      case Mood.happy:
        leftPath
          ..moveTo(c.dx - eyeOffsetX - browLen / 2, browY + r * 0.03)
          ..quadraticBezierTo(
            c.dx - eyeOffsetX,
            browY - r * 0.08,
            c.dx - eyeOffsetX + browLen / 2,
            browY + r * 0.03,
          );
        rightPath
          ..moveTo(c.dx + eyeOffsetX - browLen / 2, browY + r * 0.03)
          ..quadraticBezierTo(
            c.dx + eyeOffsetX,
            browY - r * 0.08,
            c.dx + eyeOffsetX + browLen / 2,
            browY + r * 0.03,
          );
        break;
    }

    _drawPathGrow(canvas, leftPath, t, paint);
    _drawPathGrow(canvas, rightPath, t, paint);
  }

  /// Grows a stroke from its start point to (length * t).
  void _drawPathGrow(Canvas canvas, Path path, double t, Paint paint) {
    if (t >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  /// Grows a stroke from its midpoint outward in both directions —
  /// gives a "spreading smile" feel for mouth arcs and lines.
  void _drawSpreadFromCenter(Canvas canvas, Path path, double t, Paint paint) {
    if (t >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      final mid = metric.length / 2;
      final half = metric.length * 0.5 * t;
      canvas.drawPath(metric.extractPath(mid - half, mid + half), paint);
    }
  }

  void _drawMouth(Canvas canvas, Offset c, double r, double t) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..strokeCap = StrokeCap.round;

    final mouthY = c.dy + r * 0.25;
    final mouthW = r * 0.7;

    switch (mood) {
      case Mood.happy:
        // Filled smile + tongue — scale + opacity reveal.
        canvas.save();
        canvas.translate(c.dx, mouthY);
        canvas.scale(t);
        canvas.translate(-c.dx, -mouthY);

        final fill = Paint()..color = Colors.black87.withValues(alpha: t);
        final rect = Rect.fromCenter(
          center: Offset(c.dx, mouthY),
          width: mouthW,
          height: r * 0.6,
        );
        canvas.drawPath(Path()..addArc(rect, 0, math.pi), fill);

        final tonguePaint = Paint()
          ..color = const Color(0xFFEF6B7E).withValues(alpha: t);
        final tongueRect = Rect.fromCenter(
          center: Offset(c.dx, mouthY + r * 0.1),
          width: mouthW * 0.6,
          height: r * 0.3,
        );
        canvas.drawPath(Path()..addArc(tongueRect, 0, math.pi), tonguePaint);
        canvas.restore();
        break;
      case Mood.good:
        final rect = Rect.fromCenter(
          center: Offset(c.dx, mouthY - r * 0.05),
          width: mouthW * 0.85,
          height: r * 0.4,
        );
        _drawSpreadFromCenter(
          canvas,
          Path()..addArc(rect, 0, math.pi),
          t,
          paint,
        );
        break;
      case Mood.neutral:
        _drawSpreadFromCenter(
          canvas,
          Path()
            ..moveTo(c.dx - mouthW / 2, mouthY)
            ..lineTo(c.dx + mouthW / 2, mouthY),
          t,
          paint,
        );
        break;
      case Mood.sad:
        final rect = Rect.fromCenter(
          center: Offset(c.dx, mouthY + r * 0.15),
          width: mouthW * 0.85,
          height: r * 0.4,
        );
        _drawSpreadFromCenter(
          canvas,
          Path()..addArc(rect, math.pi, math.pi),
          t,
          paint,
        );
        break;
      case Mood.angry:
        final path = Path()..moveTo(c.dx - mouthW / 2, mouthY);
        const segments = 4;
        for (int i = 1; i <= segments; i++) {
          final x = c.dx - mouthW / 2 + (mouthW / segments) * i;
          final y = mouthY + (i.isEven ? -r * 0.07 : r * 0.07);
          path.lineTo(x, y);
        }
        _drawSpreadFromCenter(canvas, path, t, paint);
        break;
    }
  }

  void _drawBlush(Canvas canvas, Offset c, double r, double t) {
    final paint = Paint()..color = Colors.pinkAccent.withValues(alpha: 0.35 * t);
    final radius = r * 0.13 * t;
    canvas.drawCircle(Offset(c.dx - r * 0.5, c.dy + r * 0.1), radius, paint);
    canvas.drawCircle(Offset(c.dx + r * 0.5, c.dy + r * 0.1), radius, paint);
  }

  void _drawTear(Canvas canvas, Offset c, double r, double t) {
    final dy = r * 0.04 * (1 - t); // small drip-down as it reveals
    final path = Path()
      ..moveTo(c.dx - r * 0.38, c.dy - r * 0.05 + dy)
      ..quadraticBezierTo(
        c.dx - r * 0.30,
        c.dy + r * 0.10 + dy,
        c.dx - r * 0.34,
        c.dy + r * 0.20 + dy,
      )
      ..quadraticBezierTo(
        c.dx - r * 0.42,
        c.dy + r * 0.10 + dy,
        c.dx - r * 0.38,
        c.dy - r * 0.05 + dy,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF4FC3F7).withValues(alpha: t),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue.shade700.withValues(alpha: t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant MoodFacePainter old) =>
      old.mood != mood ||
      old.previousMood != previousMood ||
      old.revealProgress != revealProgress;
}
