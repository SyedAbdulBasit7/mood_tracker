import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood.dart';

/// Persists mood entries to localStorage (via shared_preferences on web).
class MoodStorage {
  static const _key = 'mood_entries_v1';

  Future<List<MoodEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<MoodEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        json.encode(entries.map((e) => e.toJson()).toList(growable: false));
    await prefs.setString(_key, encoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
