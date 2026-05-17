import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';
import '../utils/mood_storage.dart';
import '../widgets/animated_mood_face.dart';
import '../widgets/color_wash_overlay.dart';
import '../widgets/mood_particle_burst.dart';
import '../widgets/mood_picker_button.dart';
import '../widgets/mood_sparkle_rain.dart';
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

  /// The most recently logged mood. Drives the picker's selected state and
  /// the "Logged: …" label. Independent of [_reviewEntry] so the picker
  /// always reflects the user's actual current mood, not what they're
  /// scrubbing through.
  Mood? _selectedMood;

  /// When non-null, the user is reviewing a past entry. The preview face
  /// and background gradient follow this; the picker does not.
  MoodEntry? _reviewEntry;

  // Card tap pulse trigger.
  int _animateTrigger = 0;
  int? _animateIndex;

  // Radial color wash trigger.
  Offset? _washOrigin;
  int _washTrigger = 0;

  // Screen-wide sparkle rain trigger. Fires only when *entering* review on
  // a past entry (tap-to-toggle-off does not retrigger).
  Mood? _rainMood;
  int _rainTrigger = 0;

  static const _baseFrom = Color(0xFFFFF7E6);
  static const _baseTo = Color(0xFFE8F4FF);

  Mood? get _displayMood => _reviewEntry?.mood ?? _selectedMood;
  bool get _isReviewing => _reviewEntry != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _storage.load();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (!mounted) return;
    setState(() {
      _entries = entries.take(50).toList();
      _loading = false;
      _selectedMood = entries.isNotEmpty ? entries.first.mood : null;
    });
  }

  Future<void> _logMood(Mood mood, Offset tapPosition) async {
    final newEntry = MoodEntry(mood: mood, timestamp: DateTime.now());
    final updated = [newEntry, ..._entries];
    setState(() {
      _entries = updated;
      _selectedMood = mood;
      _reviewEntry = null; // logging a new entry exits review mode
      _washOrigin = tapPosition;
      _washTrigger++;
      _animateIndex = null;
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

  void _handleCardTap(int index, MoodEntry entry) {
    setState(() {
      final wasReviewingThis = _reviewEntry?.timestamp == entry.timestamp;
      if (wasReviewingThis) {
        // Tapping the already-reviewed card exits review (no rain).
        _reviewEntry = null;
      } else {
        // Entering review of this entry — fire the sparkle rain.
        _reviewEntry = entry;
        _rainMood = entry.mood;
        _rainTrigger++;
      }
      _animateIndex = index;
      _animateTrigger++;
    });
  }

  void _exitReview() {
    if (_reviewEntry == null) return;
    setState(() => _reviewEntry = null);
  }

  Future<void> _deleteEntry(int index) async {
    if (index < 0 || index >= _entries.length) return;
    final removed = _entries[index];
    final updated = List<MoodEntry>.from(_entries)..removeAt(index);
    setState(() {
      _entries = updated;
      if (_reviewEntry?.timestamp == removed.timestamp) {
        _reviewEntry = null;
      }
      if (updated.isEmpty) {
        _selectedMood = null;
      } else if (index == 0) {
        // Removed the latest entry — bump selection to the new latest.
        _selectedMood = updated.first.mood;
      }
      _animateIndex = null;
    });
    await _storage.save(updated);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed ${removed.mood.label}'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _undoDelete(index, removed),
        ),
      ),
    );
  }

  Future<void> _undoDelete(int originalIndex, MoodEntry entry) async {
    final updated = List<MoodEntry>.from(_entries);
    final insertAt = originalIndex.clamp(0, updated.length);
    updated.insert(insertAt, entry);
    setState(() {
      _entries = updated;
      _selectedMood = updated.isNotEmpty ? updated.first.mood : _selectedMood;
    });
    await _storage.save(updated);
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all entries?'),
        content: const Text(
          'This removes every logged mood from this browser.',
        ),
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
      if (!mounted) return;
      setState(() {
        _entries = [];
        _selectedMood = null;
        _reviewEntry = null;
      });
    }
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  Color _innerBg() {
    final m = _displayMood;
    if (m == null) return _baseFrom;
    return Color.lerp(_baseFrom, m.accent, 0.35) ?? _baseFrom;
  }

  Color _outerBg() {
    final m = _displayMood;
    if (m == null) return _baseTo;
    return Color.lerp(_baseTo, m.accent, 0.10) ?? _baseTo;
  }

  @override
  Widget build(BuildContext context) {
    final last7 = _entries.take(7).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: animated radial gradient backdrop.
          Positioned.fill(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: _innerBg()),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeInOutCubic,
              builder: (context, innerColor, _) {
                return TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: _outerBg()),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeInOutCubic,
                  builder: (context, outerColor, _) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.05),
                          radius: 1.1,
                          colors: [
                            innerColor ?? _baseFrom,
                            outerColor ?? _baseTo,
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Layer 2: radial color wash from the tap point.
          Positioned.fill(
            child: ColorWashOverlay(
              origin: _washOrigin,
              color: _selectedMood?.accent ?? Colors.transparent,
              triggerKey: _washTrigger,
            ),
          ),

          // Layer 2b: mood-themed particle burst from the tap point.
          Positioned.fill(
            child: MoodParticleBurst(
              origin: _washOrigin,
              mood: _selectedMood,
              triggerKey: _washTrigger,
            ),
          ),

          // Layer 3: content. On mobile (vertical timeline), the header /
          // preview / picker stay fixed and only the entries list scrolls.
          // On desktop (horizontal timeline) the whole page is scrollable
          // as a fallback for short windows.
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_isVerticalTimeline(context)
                    ? _buildMobileLayout(last7)
                    : _buildDesktopLayout(last7)),
          ),

          // Layer 4: screen-wide sparkle rain. Painted above the content so
          // sparkles visibly fall across everything; IgnorePointer keeps
          // taps falling through to the cards underneath.
          Positioned.fill(
            child: MoodSparkleRain(
              mood: _rainMood,
              triggerKey: _rainTrigger,
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile: fixed top sections, only the entries list scrolls.
  Widget _buildMobileLayout(List<MoodEntry> last7) {
    return Column(
      children: [
        _buildHeader(),
        _buildPreview(),
        _buildPicker(),
        const SizedBox(height: 12),
        _buildTimelineHeader(),
        const SizedBox(height: 8),
        Expanded(child: _buildTimeline(last7)),
      ],
    );
  }

  /// Desktop: whole page is in a SingleChildScrollView as a fallback for
  /// short windows. The horizontal timeline already scrolls horizontally
  /// inside its 280 px row, so entries-only scrolling is preserved at the
  /// timeline level too.
  Widget _buildDesktopLayout(List<MoodEntry> last7) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
    );
  }

  bool _isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 400;

  Widget _buildHeader() {
    final compact = _isCompact(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 20, compact ? 12 : 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mood Tracker',
            style: TextStyle(
              fontSize: compact ? 22 : 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D2D2D),
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
    final mood = _displayMood ?? Mood.neutral;
    final compact = _isCompact(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          MouseRegion(
            cursor: _isReviewing
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: _isReviewing ? _exitReview : null,
              child: AnimatedMoodFace(
                mood: mood,
                size: compact ? 108 : 130,
                breathe: _displayMood != null,
                breathDepth: 0.035,
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              _previewLabelText(),
              key: ValueKey(_previewLabelKey()),
              style: TextStyle(
                fontSize: 16,
                color: _isReviewing ? mood.accent : Colors.black87,
                fontWeight: _isReviewing ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: _isReviewing
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton.icon(
                      onPressed: _exitReview,
                      icon: const Icon(Icons.arrow_back, size: 14),
                      label: const Text(
                        'Back to latest',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        minimumSize: const Size(0, 28),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _previewLabelText() {
    final r = _reviewEntry;
    if (r != null) {
      final fmt = DateFormat('MMM d • h:mm a').format(r.timestamp);
      return '${r.mood.label} on $fmt';
    }
    if (_selectedMood != null) {
      return 'Logged: ${_selectedMood!.label}';
    }
    return 'How are you feeling?';
  }

  String _previewLabelKey() {
    final r = _reviewEntry;
    if (r != null) return 'review-${r.timestamp.toIso8601String()}';
    return _selectedMood?.name ?? 'empty';
  }

  Widget _buildPicker() {
    final hasSelection = _selectedMood != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: Mood.values
            .map(
              (m) => MoodPickerButton(
                mood: m,
                isSelected: m == _selectedMood,
                isDimmed: hasSelection && m != _selectedMood,
                onTap: (pos) => _logMood(m, pos),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _isCompact(context) ? 16 : 24),
      child: const Align(
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

  /// Narrow viewports switch the timeline from a horizontally-scrolling row
  /// of vertical cards (desktop) to a vertical list of horizontal row-cards
  /// (mobile). 600 px is the standard Material breakpoint between phone and
  /// tablet, and it sidesteps the gesture conflict between horizontal-card
  /// scrolling and the page's vertical scroll on touch devices.
  bool _isVerticalTimeline(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

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

    return _isVerticalTimeline(context)
        ? _buildVerticalTimeline(last7)
        : _buildHorizontalTimeline(last7);
  }

  Widget _buildVerticalTimeline(List<MoodEntry> last7) {
    final hPad = _isCompact(context) ? 16.0 : 24.0;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 16),
      itemCount: last7.length,
      itemBuilder: (ctx, i) {
        final entry = last7[i];
        final isAnimating = _animateIndex == i;
        final isReviewing =
            _isReviewing && _reviewEntry?.timestamp == entry.timestamp;
        final isDimmed = _isReviewing && !isReviewing;
        return TimelineCard(
          entry: entry,
          layout: Axis.horizontal,
          animateKey: isAnimating ? _animateTrigger : null,
          isReviewing: isReviewing,
          isDimmed: isDimmed,
          onTap: () => _handleCardTap(i, entry),
          onDelete: () => _deleteEntry(i),
        );
      },
    );
  }

  Widget _buildHorizontalTimeline(List<MoodEntry> last7) {
    final scrollBehavior = ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      },
      scrollbars: false,
    );

    return SizedBox(
      // Extra height vs. the card itself so the scale-up + halo on the
      // reviewed entry have room to breathe without clipping at the top
      // or bottom of the ListView viewport.
      height: 280,
      child: ScrollConfiguration(
        behavior: scrollBehavior,
        child: Listener(
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent &&
                _timelineController.hasClients) {
              final delta = signal.scrollDelta.dy;
              if (delta != 0) {
                final target = (_timelineController.offset + delta).clamp(
                  _timelineController.position.minScrollExtent,
                  _timelineController.position.maxScrollExtent,
                );
                _timelineController.jumpTo(target);
              }
            }
          },
          child: ListView.builder(
            controller: _timelineController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: last7.length,
            itemBuilder: (ctx, i) {
              final entry = last7[i];
              final isAnimating = _animateIndex == i;
              final isReviewing = _isReviewing &&
                  _reviewEntry?.timestamp == entry.timestamp;
              final isDimmed = _isReviewing && !isReviewing;
              return Center(
                child: TimelineCard(
                  entry: entry,
                  animateKey: isAnimating ? _animateTrigger : null,
                  isReviewing: isReviewing,
                  isDimmed: isDimmed,
                  onTap: () => _handleCardTap(i, entry),
                  onDelete: () => _deleteEntry(i),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
