import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/models/mood.dart';

void main() {
  group('MoodEntry serialization', () {
    test('round-trips through JSON', () {
      final now = DateTime.parse('2026-05-16T10:30:00.000Z');
      final entry = MoodEntry(mood: Mood.happy, timestamp: now);
      final json = entry.toJson();
      final back = MoodEntry.fromJson(json);
      expect(back.mood, Mood.happy);
      expect(back.timestamp.toIso8601String(), now.toIso8601String());
    });

    test('falls back to neutral on unknown mood', () {
      final back = MoodEntry.fromJson({
        'mood': 'something_unknown',
        'timestamp': DateTime.now().toIso8601String(),
      });
      expect(back.mood, Mood.neutral);
    });
  });

  test('every Mood has a non-null label and accent', () {
    for (final m in Mood.values) {
      expect(m.label, isNotEmpty);
      expect(m.accent, isNotNull);
    }
  });
}
