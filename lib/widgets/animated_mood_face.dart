import 'package:flutter/material.dart';
import '../models/mood.dart';
import 'mood_face_painter.dart';

/// A painted mood face wired up with three orchestrated animations:
///   1. **Reveal** — on every [mood] change, features (eyes → brows → mouth →
///      extras) draw in sequentially and the face color cross-fades from the
///      previous mood. Driven by an 1100ms controller.
///   2. **Breathing** — when [breathe] is true, the whole face slowly scales
///      up/down (default amplitude [breathDepth] = 0.03 over 3200ms). Used
///      to communicate the "selected" picker face and the live preview.
///   3. **Wiggle** — when [animateKey] changes, plays a brief spring scale +
///      rotation. Used for timeline-card taps.
class AnimatedMoodFace extends StatefulWidget {
  final Mood mood;
  final double size;
  final Object? animateKey;
  final bool breathe;
  final double breathDepth;
  final Duration breathDuration;

  const AnimatedMoodFace({
    super.key,
    required this.mood,
    this.size = 80,
    this.animateKey,
    this.breathe = false,
    this.breathDepth = 0.03,
    this.breathDuration = const Duration(milliseconds: 3200),
  });

  @override
  State<AnimatedMoodFace> createState() => _AnimatedMoodFaceState();
}

class _AnimatedMoodFaceState extends State<AnimatedMoodFace>
    with TickerProviderStateMixin {
  late final AnimationController _reveal;
  late final AnimationController _wiggle;
  late final AnimationController _breath;

  late final Animation<double> _wiggleScale;
  late final Animation<double> _wiggleRotation;
  late final Animation<double> _breathScale;

  Mood? _previousMood;

  @override
  void initState() {
    super.initState();

    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      value: 1.0, // fully revealed by default
    );

    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _wiggleScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.94), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _wiggle, curve: Curves.easeOutCubic));
    _wiggleRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.10), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.10, end: 0.10), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.10, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _wiggle, curve: Curves.easeInOut));

    _breath = AnimationController(
      vsync: this,
      duration: widget.breathDuration,
    );
    _breathScale =
        Tween<double>(begin: 1.0, end: 1.0 + widget.breathDepth).animate(
      CurvedAnimation(parent: _breath, curve: Curves.easeInOutSine),
    );

    if (widget.breathe) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedMoodFace oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mood != oldWidget.mood) {
      _previousMood = oldWidget.mood;
      _reveal.forward(from: 0);
    }

    if (widget.animateKey != null &&
        widget.animateKey != oldWidget.animateKey) {
      _wiggle.forward(from: 0);
    }

    if (widget.breathe != oldWidget.breathe) {
      if (widget.breathe) {
        _breath.repeat(reverse: true);
      } else {
        _breath.stop();
        _breath.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _wiggle.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_reveal, _wiggle, _breath]),
      builder: (context, _) {
        return Transform.rotate(
          angle: _wiggleRotation.value,
          child: Transform.scale(
            scale: _wiggleScale.value * _breathScale.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: MoodFacePainter(
                  mood: widget.mood,
                  previousMood: _previousMood,
                  revealProgress: _reveal.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
