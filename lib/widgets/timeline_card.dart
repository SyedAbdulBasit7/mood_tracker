import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';
import 'animated_mood_face.dart';

class TimelineCard extends StatelessWidget {
  final MoodEntry entry;
  final Object? animateKey;
  final VoidCallback onTap;

  const TimelineCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.animateKey,
  });

  @override
  Widget build(BuildContext context) {
    final date = entry.timestamp;
    final dateStr = DateFormat('MMM d').format(date);
    final timeStr = DateFormat('h:mm a').format(date);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: entry.mood.accent, width: 3),
          boxShadow: [
            BoxShadow(
              color: entry.mood.accent.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedMoodFace(
              mood: entry.mood,
              size: 78,
              animateKey: animateKey,
            ),
            const SizedBox(height: 8),
            Text(
              entry.mood.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: entry.mood.accent,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
