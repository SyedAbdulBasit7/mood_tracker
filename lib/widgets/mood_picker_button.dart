import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mood.dart';
import 'animated_mood_face.dart';

/// A picker button with three orchestrated states:
///   * **Idle**         — full color, full opacity. The face inside breathes
///                        only when [isSelected] is true.
///   * **Hover (web)**  — face lifts and scales to 1.08 with a brighter halo.
///   * **Dimmed**       — when another mood is selected, opacity drops to
///                        0.35, scale to 0.88, color desaturated.
///   * **Tap moment**   — fires haptic + elastic scale spring (1.0 → 1.18 →
///                        ~0.96 → 1.0) and reports the global tap position
///                        upstream so the color wash can originate from
///                        exactly the finger.
class MoodPickerButton extends StatefulWidget {
  final Mood mood;
  final bool isSelected;
  final bool isDimmed;
  final void Function(Offset globalTapPosition) onTap;

  const MoodPickerButton({
    super.key,
    required this.mood,
    required this.onTap,
    this.isSelected = false,
    this.isDimmed = false,
  });

  @override
  State<MoodPickerButton> createState() => _MoodPickerButtonState();
}

class _MoodPickerButtonState extends State<MoodPickerButton>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late final AnimationController _tap;
  late final Animation<double> _tapScale;

  // Standard luminance matrix — drops chroma so dimmed faces look "muted"
  // rather than just translucent.
  static const List<double> _grayscaleMatrix = <double>[
    0.213, 0.715, 0.072, 0, 0, //
    0.213, 0.715, 0.072, 0, 0, //
    0.213, 0.715, 0.072, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  void initState() {
    super.initState();
    _tap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.96), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _tap, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails d) {
    _tap.forward(from: 0);
    HapticFeedback.selectionClick();
    widget.onTap(d.globalPosition);
  }

  @override
  Widget build(BuildContext context) {
    final dimmed = widget.isDimmed && !widget.isSelected;
    final hoverScale = _hovering ? 1.08 : 1.0;
    final dimScale = dimmed ? 0.88 : 1.0;

    Widget face = AnimatedMoodFace(
      mood: widget.mood,
      size: 72,
      breathe: widget.isSelected,
      breathDepth: 0.04,
      breathDuration: const Duration(milliseconds: 2800),
    );

    if (dimmed) {
      face = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: AnimatedMoodFace(mood: widget.mood, size: 72),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          opacity: dimmed ? 0.35 : 1.0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            offset: Offset(0, _hovering ? -0.04 : 0),
            child: AnimatedBuilder(
              animation: _tap,
              builder: (context, child) {
                return Transform.scale(
                  scale: _tapScale.value * hoverScale * dimScale,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.mood.accent.withValues(
                              alpha: _hovering
                                  ? 0.55
                                  : (widget.isSelected ? 0.50 : 0.30),
                            ),
                            blurRadius: _hovering || widget.isSelected
                                ? 22
                                : 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: face,
                    ),
                    const SizedBox(height: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected
                            ? widget.mood.accent
                            : Colors.black87,
                      ),
                      child: Text(widget.mood.label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
