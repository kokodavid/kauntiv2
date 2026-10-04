import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../design/app_type_scale.dart';

/// The floating transport pill: play/pause, a scrubber ticked with the
/// key moments, the time/distance readout, and a speed toggle
/// that cycles with one tap rather than three separate chips.
class ReplayPlaybackBar extends StatelessWidget {
  const ReplayPlaybackBar({
    super.key,
    required this.playing,
    required this.pausedAtMoment,
    required this.position,
    required this.lastIndex,
    required this.tickIndices,
    required this.readout,
    required this.speedLabel,
    required this.onTogglePlay,
    required this.onScrub,
    required this.onCycleSpeed,
  });

  final bool playing;

  /// Whether replay is currently paused at a key moment (changes the
  /// play button's tooltip to "Continue replay").
  final bool pausedAtMoment;
  final double position;
  final int lastIndex;

  /// The point index of each key moment, drawn as a tick on the track.
  final List<int> tickIndices;
  final String readout;
  final String speedLabel;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onScrub;
  final VoidCallback onCycleSpeed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.foreground,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 14, 10),
        child: Row(
          children: [
            IconButton.filled(
              onPressed: onTogglePlay,
              tooltip: playing
                  ? 'Pause replay'
                  : pausedAtMoment
                  ? 'Continue replay'
                  : 'Play replay',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentForeground,
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  key: ValueKey(playing),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReplayScrubber(
                    position: position,
                    lastIndex: lastIndex,
                    tickIndices: tickIndices,
                    onScrub: onScrub,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          readout,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypeScale.small.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onCycleSpeed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            speedLabel,
                            style: AppTypeScale.pill.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal track ticked at each key moment's position; tap or drag
/// anywhere along it to scrub.
class ReplayScrubber extends StatelessWidget {
  const ReplayScrubber({
    super.key,
    required this.position,
    required this.lastIndex,
    required this.tickIndices,
    required this.onScrub,
  });

  final double position;
  final int lastIndex;
  final List<int> tickIndices;
  final ValueChanged<double> onScrub;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void handle(double dx) {
          if (width <= 0 || lastIndex <= 0) return;
          final fraction = (dx / width).clamp(0.0, 1.0);
          onScrub(fraction * lastIndex);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => handle(details.localPosition.dx),
          onHorizontalDragUpdate: (details) => handle(details.localPosition.dx),
          child: SizedBox(
            height: 20,
            width: double.infinity,
            child: CustomPaint(
              painter: _ScrubberPainter(
                progress: lastIndex == 0
                    ? 0
                    : (position / lastIndex).clamp(0.0, 1.0),
                tickFractions: lastIndex == 0
                    ? const []
                    : [
                        for (final index in tickIndices)
                          (index / lastIndex).clamp(0.0, 1.0),
                      ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScrubberPainter extends CustomPainter {
  _ScrubberPainter({required this.progress, required this.tickFractions});

  final double progress;
  final List<double> tickFractions;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final filled = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), track);
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width * progress, midY),
      filled,
    );
    final tick = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (final fraction in tickFractions) {
      canvas.drawCircle(Offset(size.width * fraction, midY), 3, tick);
    }
    canvas.drawCircle(
      Offset(size.width * progress, midY),
      6,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _ScrubberPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      !listEquals(oldDelegate.tickFractions, tickFractions);
}
