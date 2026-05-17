import 'package:flutter/material.dart';
import '../models/mood.dart';
import 'mood_face_painter.dart';

/// A face that wiggles + scales briefly when [animateKey] changes.
class AnimatedMoodFace extends StatefulWidget {
  final Mood mood;
  final double size;
  final Object? animateKey;

  const AnimatedMoodFace({
    super.key,
    required this.mood,
    this.size = 80,
    this.animateKey,
  });

  @override
  State<AnimatedMoodFace> createState() => _AnimatedMoodFaceState();
}

class _AnimatedMoodFaceState extends State<AnimatedMoodFace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.92), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.18), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.18, end: 0.18), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.18, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedMoodFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateKey != null &&
        widget.animateKey != oldWidget.animateKey) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: MoodFacePainter(mood: widget.mood),
        ),
      ),
    );
  }
}
