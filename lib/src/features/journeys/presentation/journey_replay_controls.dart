import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/journey_moments.dart';
import '../domain/journey_replay.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';

/// The card floating over the full-screen map: the Journey's title and
/// facts, the key moment replay stopped at (if any), play / pause, the
/// scrubber, the "time · distance" readout and speed.
class JourneyReplayControls extends StatelessWidget {
  const JourneyReplayControls({
    super.key,
    required this.summary,
    required this.distanceMeters,
    required this.playing,
    required this.position,
    required this.lastIndex,
    required this.readout,
    required this.speed,
    required this.moments,
    required this.momentTime,
    required this.onTogglePlay,
    required this.onScrub,
    required this.onSpeed,
  });

  final JourneySummary summary;

  /// The server's distance once uploaded, else measured from the route.
  final double distanceMeters;
  final bool playing;
  final double position;
  final int lastIndex;
  final String readout;
  final JourneyReplaySpeed speed;

  /// The moments replay is paused at; empty while it plays.
  final List<JourneyMoment> moments;

  /// When those moments happened.
  final DateTime? momentTime;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onScrub;
  final ValueChanged<JourneyReplaySpeed> onSpeed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryHeader(summary: summary, distanceMeters: distanceMeters),
            const Divider(height: 16),
            for (final moment in moments)
              _MomentRow(moment: moment, time: momentTime),
            if (moments.isNotEmpty) const Divider(height: 16),
            Row(
              children: [
                IconButton.filled(
                  onPressed: onTogglePlay,
                  tooltip: playing
                      ? 'Pause replay'
                      : moments.isNotEmpty
                      ? 'Continue replay'
                      : 'Play replay',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentForeground,
                  ),
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                ),
                Expanded(
                  child: Slider(
                    value: position,
                    max: lastIndex.toDouble(),
                    activeColor: AppColors.accent,
                    onChanged: onScrub,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 4),
                Expanded(child: Text(readout, style: AppTypeScale.itemTitle)),
                for (final option in JourneyReplaySpeed.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(option.label),
                      selected: option == speed,
                      onSelected: (_) => onSpeed(option),
                      selectedColor: AppColors.accent,
                      labelStyle: AppTypeScale.pill.copyWith(
                        color: option == speed
                            ? AppColors.accentForeground
                            : AppColors.foreground,
                      ),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentRow extends StatelessWidget {
  const _MomentRow({required this.moment, required this.time});

  final JourneyMoment moment;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    final (icon, title, detail) = _describe(moment);
    final at = time == null
        ? null
        : TimeOfDay.fromDateTime(time!.toLocal()).format(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.lockedFill,
            foregroundColor: AppColors.accent,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypeScale.itemTitle),
                Text(
                  at == null ? detail : '$at · $detail',
                  style: AppTypeScale.small.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static (IconData, String, String) _describe(JourneyMoment moment) {
    final duration = moment.duration;
    final took = duration == null ? null : JourneyFormat.duration(duration);
    return switch (moment.kind) {
      JourneyMomentKind.recordingBreak => (
        Icons.pause_circle_outline,
        'Recording paused',
        took == null ? 'Picked up again later' : 'Picked up again $took later',
      ),
      JourneyMomentKind.longStop => (
        Icons.schedule,
        took == null ? 'A long stop' : 'Stopped for $took',
        'Long stop',
      ),
      JourneyMomentKind.countyCrossing => (
        Icons.flag_outlined,
        'Entered ${moment.name ?? 'a new county'}',
        'County crossing',
      ),
      JourneyMomentKind.savedPlace => (
        Icons.bookmark_outline,
        'Passed ${moment.name ?? 'a saved place'}',
        'A place you saved',
      ),
    };
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary, required this.distanceMeters});

  final JourneySummary summary;
  final double distanceMeters;

  @override
  Widget build(BuildContext context) {
    final started = TimeOfDay.fromDateTime(
      summary.startedAt.toLocal(),
    ).format(context);
    final facts = [
      JourneyFormat.distance(distanceMeters),
      JourneyFormat.duration(summary.duration),
      'Started $started',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypeScale.sectionTitle,
          ),
          const SizedBox(height: 2),
          Text(
            facts,
            style: AppTypeScale.small.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          if (!summary.isUploaded)
            Text(
              'On this phone, waiting to upload to your account.',
              style: AppTypeScale.small.copyWith(color: AppColors.pendingFill),
            ),
        ],
      ),
    );
  }
}

/// A message in place of the replay (deleted, offline, too few points).
class JourneyReplayMessage extends StatelessWidget {
  const JourneyReplayMessage({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center, style: AppTypeScale.body),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
