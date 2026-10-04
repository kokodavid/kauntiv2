import 'package:flutter/material.dart';

import '../../../core/widgets/replay_playback_bar.dart';
import '../domain/journey_moments.dart';
import '../domain/journey_replay.dart';

/// The shared scrubber, under the name Journeys tests and code know it by.
typedef JourneyReplayScrubber = ReplayScrubber;

/// The floating transport pill for a Journey replay: the shared
/// [ReplayPlaybackBar] fed from Journey moments and speeds.
class JourneyReplayPlaybackBar extends StatelessWidget {
  const JourneyReplayPlaybackBar({
    super.key,
    required this.playing,
    required this.pausedAtMoment,
    required this.position,
    required this.lastIndex,
    required this.moments,
    required this.readout,
    required this.speed,
    required this.onTogglePlay,
    required this.onScrub,
    required this.onCycleSpeed,
  });

  final bool playing;
  final bool pausedAtMoment;
  final double position;
  final int lastIndex;
  final List<JourneyMoment> moments;
  final String readout;
  final JourneyReplaySpeed speed;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onScrub;
  final VoidCallback onCycleSpeed;

  @override
  Widget build(BuildContext context) {
    return ReplayPlaybackBar(
      playing: playing,
      pausedAtMoment: pausedAtMoment,
      position: position,
      lastIndex: lastIndex,
      tickIndices: [for (final m in moments) m.index],
      readout: readout,
      speedLabel: speed.label,
      onTogglePlay: onTogglePlay,
      onScrub: onScrub,
      onCycleSpeed: onCycleSpeed,
    );
  }
}
