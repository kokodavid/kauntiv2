import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
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
    final stats = [
      (JourneyFormat.distance(distanceMeters), 'DISTANCE'),
      if (averageSpeedMps != null)
        (JourneyFormat.speed(averageSpeedMps), 'AVG'),
      if (topSpeedMps != null) (JourneyFormat.speed(topSpeedMps), 'TOP'),
      if (highestElevationMeters != null)
        (JourneyFormat.elevation(highestElevationMeters), 'PEAK'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            for (final (index, entry) in stats.indexed) ...[
              if (index > 0)
                const SizedBox(
                  height: 28,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.cardBorder,
                  ),
                ),
              Expanded(child: _StatTile(value: entry.$1, label: entry.$2)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final parts = value.split(' ');
    final number = parts.first;
    final unit = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: number, style: AppTypeScale.compactTitle),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: AppTypeScale.small.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypeScale.statLabel),
      ],
    );
  }
}
