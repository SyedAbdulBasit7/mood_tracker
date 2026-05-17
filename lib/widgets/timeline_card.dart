import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';
import 'animated_mood_face.dart';

/// One entry in the timeline.
///
/// [layout] picks between two visual orientations:
///   * **Axis.vertical** (default) — used when the timeline scrolls
///     horizontally on desktop. Card is 140 px wide; content stacks
///     face-on-top. Swipe-up deletes.
///   * **Axis.horizontal** — used when the timeline scrolls vertically
///     on mobile. Card stretches to parent width; content is a Row with
///     the face on the left and labels on the right. Swipe-left-or-right
///     deletes; a colored delete background reveals during the drag.
///
/// External visual states are layout-agnostic:
///   * **isReviewing** — this entry is the active one. Persistent 1.05
///     scale, brighter halo, thicker accent border.
///   * **isDimmed** — another entry is being reviewed. Opacity 0.55,
///     scale 0.95.
///   * **Hover (web)** — soft lift + a fade-in × delete button at top-right.
///     On the vertical-layout card, content slides left on hover to make
///     room for the ×.
class TimelineCard extends StatefulWidget {
  final MoodEntry entry;
  final Object? animateKey;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isReviewing;
  final bool isDimmed;
  final Axis layout;

  const TimelineCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onDelete,
    this.animateKey,
    this.isReviewing = false,
    this.isDimmed = false,
    this.layout = Axis.vertical,
  });

  @override
  State<TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<TimelineCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _halo;
  late final Animation<double> _borderBoost;

  bool _hovering = false;

  bool get _isVerticalCard => widget.layout == Axis.vertical;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.97), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.04), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOutCubic));

    _halo = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOutCubic));

    _borderBoost = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 75),
    ]).animate(_pulse);
  }

  @override
  void didUpdateWidget(covariant TimelineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateKey != null &&
        widget.animateKey != oldWidget.animateKey) {
      _pulse.forward(from: 0);
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.entry.mood.accent;
    final isReviewing = widget.isReviewing;
    final isDimmed = widget.isDimmed;
    final canDelete = widget.onDelete != null;

    final card = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        opacity: isDimmed ? 0.55 : 1.0,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final extraBorder = 2.0 * _borderBoost.value;
              final hoverBlur = _hovering ? 18.0 : 12.0;
              final reviewBlur = isReviewing ? 14.0 : 0.0;
              final haloBlur = hoverBlur + reviewBlur + 22 * _halo.value;
              final haloSpread =
                  (isReviewing ? 3.0 : 0.0) + 4 * _halo.value;
              final hoverLift = _hovering ? -2.0 : 0.0;
              final stateScale =
                  isReviewing ? 1.05 : (isDimmed ? 0.95 : 1.0);
              final reviewBorder = isReviewing ? 1.5 : 0.0;

              return Transform.translate(
                offset: Offset(0, hoverLift),
                child: Transform.scale(
                  scale: _scale.value * stateScale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: _isVerticalCard ? 140 : double.infinity,
                    margin: _isVerticalCard
                        ? const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          )
                        : const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent,
                        width: 3 + extraBorder + reviewBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(
                            alpha: 0.25 +
                                0.30 * _halo.value +
                                (isReviewing ? 0.25 : 0.0),
                          ),
                          blurRadius: haloBlur,
                          spreadRadius: haloSpread,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: child,
                  ),
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _isVerticalCard ? _buildVerticalBody() : _buildHorizontalBody(),
                if (canDelete)
                  Positioned(
                    top: _isVerticalCard ? 0 : -4,
                    right: _isVerticalCard ? 0 : -4,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _hovering ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !_hovering,
                        child: _DeleteButton(
                          accent: accent,
                          onTap: widget.onDelete!,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!canDelete) return card;

    final dismissDirection = _isVerticalCard
        ? DismissDirection.up
        : DismissDirection.horizontal;

    return Dismissible(
      key: ValueKey('entry-${widget.entry.timestamp.toIso8601String()}'),
      direction: dismissDirection,
      resizeDuration: const Duration(milliseconds: 220),
      onDismissed: (_) => widget.onDelete!(),
      background: _isVerticalCard
          ? const SizedBox.shrink()
          : _swipeBackground(accent, Alignment.centerLeft),
      secondaryBackground: _isVerticalCard
          ? null
          : _swipeBackground(accent, Alignment.centerRight),
      child: card,
    );
  }

  Widget _buildVerticalBody() {
    final date = widget.entry.timestamp;
    final dateStr = DateFormat('MMM d').format(date);
    final timeStr = DateFormat('h:mm a').format(date);
    final accent = widget.entry.mood.accent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _HoverAligned(
          hovering: _hovering,
          child: AnimatedMoodFace(
            mood: widget.entry.mood,
            size: 78,
            animateKey: widget.animateKey,
          ),
        ),
        const SizedBox(height: 8),
        _HoverAligned(
          hovering: _hovering,
          child: Text(
            widget.entry.mood.label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: accent,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 4),
        _HoverAligned(
          hovering: _hovering,
          child: Text(
            dateStr,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
        _HoverAligned(
          hovering: _hovering,
          child: Text(
            timeStr,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalBody() {
    final date = widget.entry.timestamp;
    final dateStr = DateFormat('MMM d').format(date);
    final timeStr = DateFormat('h:mm a').format(date);
    final accent = widget.entry.mood.accent;

    return Row(
      children: [
        AnimatedMoodFace(
          mood: widget.entry.mood,
          size: 60,
          animateKey: widget.animateKey,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.entry.mood.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: accent,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                timeStr,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        // Right-side reserve so the × on hover never overlaps text.
        const SizedBox(width: 28),
      ],
    );
  }

  Widget _swipeBackground(Color accent, Alignment alignment) {
    final isRight = alignment == Alignment.centerRight;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment:
            isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: const [
          Icon(Icons.delete_outline, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animates its child's horizontal alignment between center (idle) and
/// centerLeft (hover) over 220 ms. Used by the vertical-layout card so it
/// "opens up" on hover to make space for the close button at the right.
class _HoverAligned extends StatelessWidget {
  final bool hovering;
  final Widget child;

  const _HoverAligned({required this.hovering, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: hovering ? Alignment.centerLeft : Alignment.center,
      child: child,
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final Color accent;
  final VoidCallback onTap;

  const _DeleteButton({required this.accent, required this.onTap});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hover ? widget.accent : Colors.white,
            border: Border.all(color: widget.accent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hover ? 0.20 : 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.close_rounded,
            size: 14,
            color: _hover ? Colors.white : widget.accent,
          ),
        ),
      ),
    );
  }
}
