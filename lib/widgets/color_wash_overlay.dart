import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A full-screen, non-interactive overlay that paints a soft radial bloom in
/// [color] starting at [origin] (screen-local coords) whenever [triggerKey]
/// changes. Single controller, 900ms — replays from scratch on every tap.
///
/// Envelope:
///   * Radius:  0 → screenDiagonal * 1.15, eased with easeOutCubic.
///   * Opacity: fades in over t∈[0,0.15], holds to t=0.7, fades out by t=1.0.
class ColorWashOverlay extends StatefulWidget {
  final Offset? origin;
  final Color color;
  final Object? triggerKey;

  const ColorWashOverlay({
    super.key,
    required this.origin,
    required this.color,
    required this.triggerKey,
  });

  @override
  State<ColorWashOverlay> createState() => _ColorWashOverlayState();
}

class _ColorWashOverlayState extends State<ColorWashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(covariant ColorWashOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerKey != null &&
        widget.triggerKey != oldWidget.triggerKey &&
        widget.origin != null) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isDismissed || widget.origin == null) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            size: Size.infinite,
            painter: _WashPainter(
              origin: widget.origin!,
              color: widget.color,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _WashPainter extends CustomPainter {
  final Offset origin;
  final Color color;
  final double progress;

  _WashPainter({
    required this.origin,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final radius =
        Curves.easeOutCubic.transform(progress) * diagonal * 1.15;

    final opacity = _opacityEnvelope(progress);
    if (opacity <= 0 || radius <= 0) return;

    final rect = Rect.fromCircle(center: origin, radius: radius);
    final shader = RadialGradient(
      colors: [
        color.withValues(alpha: 0.55 * opacity),
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 1.0],
    ).createShader(rect);

    canvas.drawCircle(origin, radius, Paint()..shader = shader);
  }

  double _opacityEnvelope(double t) {
    if (t < 0.15) return t / 0.15;
    if (t < 0.7) return 1.0;
    final fade = (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
    return Curves.easeOutQuad.transform(fade);
  }

  @override
  bool shouldRepaint(covariant _WashPainter old) =>
      old.progress != progress ||
      old.origin != origin ||
      old.color != color;
}
