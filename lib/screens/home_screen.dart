import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../utils/mood_storage.dart';
import '../widgets/animated_mood_face.dart';
import '../widgets/mood_picker_button.dart';
import '../widgets/timeline_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = MoodStorage();
  final _timelineController = ScrollController();
  List<MoodEntry> _entries = [];
  bool _loading = true;

  // Triggers the wiggle animation on a specific timeline card.
  int _animateTrigger = 0;
  int? _animateIndex;

  // Triggers the picker preview face animation when a new entry is logged.
  int _pickerAnimTrigger = 0;
  Mood? _previewMood;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _storage.load();
    // Sort newest-first for display; we'll keep storage sorted on save.
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      _entries = entries.take(50).toList();
      _loading = false;
      _previewMood = entries.isNotEmpty ? entries.first.mood : null;
    });
  }

  Future<void> _logMood(Mood mood) async {
    final newEntry = MoodEntry(mood: mood, timestamp: DateTime.now());
    final updated = [newEntry, ..._entries];
    setState(() {
      _entries = updated;
      _previewMood = mood;
      _pickerAnimTrigger++;
    });
    await _storage.save(updated);

    if (mounted && _timelineController.hasClients) {
      _timelineController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  void _animateCard(int index) {
    setState(() {
      _animateIndex = index;
      _animateTrigger++;
    });
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all entries?'),
        content: const Text('This removes every logged mood from this browser.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.clear();
      setState(() {
        _entries = [];
        _previewMood = null;
      });
    }
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last7 = _entries.take(7).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7E6), Color(0xFFE8F4FF)],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (ctx, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          children: [
                            _buildHeader(),
                            _buildPreview(),
                            _buildPicker(),
                            const SizedBox(height: 24),
                            _buildTimelineHeader(),
                            const SizedBox(height: 12),
                            _buildTimeline(last7),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mood Tracker',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D2D2D),
            ),
          ),
          if (_entries.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(foregroundColor: Colors.black54),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final mood = _previewMood ?? Mood.neutral;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          AnimatedMoodFace(
            mood: mood,
            size: 130,
            animateKey: _pickerAnimTrigger,
          ),
          const SizedBox(height: 10),
          Text(
            _previewMood == null ? 'How are you feeling?' : 'Logged: ${mood.label}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: Mood.values
            .map((m) => MoodPickerButton(mood: m, onTap: () => _logMood(m)))
            .toList(),
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Last 7 entries',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(List<MoodEntry> last7) {
    if (last7.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'No entries yet. Tap a face above to log how you feel.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.builder(
        controller: _timelineController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: last7.length,
        itemBuilder: (ctx, i) {
          final entry = last7[i];
          final isAnimating = _animateIndex == i;
          return TimelineCard(
            entry: entry,
            animateKey: isAnimating ? _animateTrigger : null,
            onTap: () => _animateCard(i),
          );
        },
      ),
    );
  }
}
