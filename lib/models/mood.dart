import 'package:flutter/material.dart';

/// The set of moods a user can log.
/// Each value carries its own accent color and label.
enum Mood {
  happy,
  good,
  neutral,
  sad,
  angry;

  String get label {
    switch (this) {
      case Mood.happy:
        return 'Happy';
      case Mood.good:
        return 'Good';
      case Mood.neutral:
        return 'Neutral';
      case Mood.sad:
        return 'Sad';
      case Mood.angry:
        return 'Angry';
    }
  }

  /// Accent color used in the timeline card and the painted face.
  Color get accent {
    switch (this) {
      case Mood.happy:
        return const Color(0xFFFFC93C); // warm yellow
      case Mood.good:
        return const Color(0xFF8BC34A); // light green
      case Mood.neutral:
        return const Color(0xFF90A4AE); // cool grey
      case Mood.sad:
        return const Color(0xFF5C9DF5); // blue
      case Mood.angry:
        return const Color(0xFFE57373); // soft red
    }
  }
}

/// A single mood log entry.
class MoodEntry {
  final Mood mood;
  final DateTime timestamp;

  const MoodEntry({required this.mood, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'mood': mood.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      mood: Mood.values.firstWhere(
        (m) => m.name == json['mood'],
        orElse: () => Mood.neutral,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
