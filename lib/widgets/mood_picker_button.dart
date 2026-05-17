import 'package:flutter/material.dart';
import '../models/mood.dart';
import 'mood_face_painter.dart';

class MoodPickerButton extends StatefulWidget {
  final Mood mood;
  final VoidCallback onTap;

  const MoodPickerButton({super.key, required this.mood, required this.onTap});

  @override
  State<MoodPickerButton> createState() => _MoodPickerButtonState();
}

class _MoodPickerButtonState extends State<MoodPickerButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_hovering ? 1.08 : 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.mood.accent
                          .withValues(alpha: _hovering ? 0.55 : 0.30),
                      blurRadius: _hovering ? 18 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: MoodFacePainter(mood: widget.mood),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.mood.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
