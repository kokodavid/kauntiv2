import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../application/journey_history.dart';
import '../domain/journey_route.dart';

/// The exploring-so-far summary at the top of the Journeys tab: total
/// distance, Trip count and counties explored, as three columns in one
/// gradient panel (the Home map stat card's language). Shown once there
/// is at least one Journey; hidden while loading or empty, since the
/// history list below already covers those states.
class JourneyHeroStats extends ConsumerWidget {
  const JourneyHeroStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeys = ref.watch(journeyHistoryListProvider).value?.journeys;
    if (journeys == null || journeys.isEmpty) return const SizedBox.shrink();

    var totalMeters = 0.0;
    var uploadedCount = 0;
    final counties = <String>{};
    for (final journey in journeys) {
      final distance = journey.distanceMeters;
      if (distance != null) {
        uploadedCount++;
        totalMeters += distance;
      }
      counties.addAll(journey.countyNames);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6F3FF), Colors.white],
          stops: [0.0, 0.85],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              // Distance is only known once a Trip has uploaded; with
              // none yet, show the dash rather than a misleading 0 km.
              value: uploadedCount == 0
                  ? '—'
                  : JourneyFormat.distance(totalMeters),
              label: uploadedCount == 0 ? 'SYNCING' : 'KM TRAVELLED',
              accent: true,
            ),
          ),
          const _Divider(),
          Expanded(
            child: _Stat(value: '${journeys.length}', label: 'TRIPS'),
          ),
          const _Divider(),
          Expanded(
            child: _Stat(
              value: '${counties.length}',
              valueSuffix: '/${CountyPaths.all.length}',
              label: 'COUNTIES',
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.cardBorder,
    );
  }
}

/// A stat column: a big numeral (with an optional lighter "/47" suffix)
/// over a small caps label, splitting a value like "834 km" so only the
/// number itself takes the numeral style and the unit reads as a caption.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.valueSuffix,
    this.accent = false,
  });

  final String value;
  final String label;
  final String? valueSuffix;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final parts = value.split(' ');
    final numeral = parts.first;
    final unit = parts.length > 1 ? parts[1] : null;
    final numeralStyle = AppTypeScale.compactTitle.copyWith(
      fontSize: 22,
      height: 26 / 22,
      color: accent ? AppColors.accent : AppColors.foreground,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(numeral, style: numeralStyle),
            if (valueSuffix != null)
              Text(
                valueSuffix!,
                style: AppTypeScale.small.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            if (unit != null) ...[
              const SizedBox(width: 3),
              Text(
                unit,
                style: AppTypeScale.small.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypeScale.statLabel,
        ),
      ],
    );
  }
}
