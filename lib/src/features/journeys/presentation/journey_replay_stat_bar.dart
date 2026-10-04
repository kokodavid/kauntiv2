import 'package:flutter/material.dart';

import '../../../core/widgets/replay_stat_bar.dart';
import '../domain/journey_route.dart';

/// The Trip's headline numbers, floating where the map meets the story
/// panel below it. Distance is always known; the rest fall away one by
/// one when missing (not yet uploaded, or no fix reported them).
class JourneyReplayStatBar extends StatelessWidget {
  const JourneyReplayStatBar({
    super.key,
    required this.distanceMeters,
    this.averageSpeedMps,
    this.topSpeedMps,
    this.highestElevationMeters,
  });

  final double distanceMeters;
  final double? averageSpeedMps;
  final double? topSpeedMps;
  final double? highestElevationMeters;

  @override
  Widget build(BuildContext context) {
    return ReplayStatBar(
      stats: [
        (value: JourneyFormat.distance(distanceMeters), label: 'DISTANCE'),
        if (averageSpeedMps != null)
          (value: JourneyFormat.speed(averageSpeedMps), label: 'AVG'),
        if (topSpeedMps != null)
          (value: JourneyFormat.speed(topSpeedMps), label: 'TOP'),
        if (highestElevationMeters != null)
          (
            value: JourneyFormat.elevation(highestElevationMeters),
            label: 'PEAK',
          ),
      ],
    );
  }
}
