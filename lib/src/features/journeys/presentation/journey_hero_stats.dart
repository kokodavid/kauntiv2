import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/journey_history.dart';
import '../domain/journey_route.dart';

/// The exploring-so-far summary at the top of the Journeys tab: total
/// distance travelled plus a couple of highlight stats, in the same
/// gradient-panel language as Home's map stat card. Shown once there is at
/// least one Journey; hidden while loading or empty, since the history
/// list below already covers those states.
class JourneyHeroStats extends ConsumerWidget {
  const JourneyHeroStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeys = ref.watch(journeyHistoryListProvider).value?.journeys;
    if (journeys == null || journeys.isEmpty) return const SizedBox.shrink();

    var totalMeters = 0.0;
    double? longestMeters;
    var uploadedCount = 0;
    var thisMonth = 0;
    final now = DateTime.now();
    for (final journey in journeys) {
      final distance = journey.distanceMeters;
      if (distance != null) {
        uploadedCount++;
        totalMeters += distance;
        if (longestMeters == null || distance > longestMeters) {
          longestMeters = distance;
        }
      }
      final started = journey.startedAt.toLocal();
      if (started.year == now.year && started.month == now.month) {
        thisMonth++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: uploadedCount == 0
                    ? const Text(
                        "You're exploring",
                        style: AppTextStyles.statNumeralCompact,
                      )
                    : _DistanceHeadline(meters: totalMeters),
              ),
              const SizedBox(width: 12),
              _CountPill(count: journeys.length),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                longestMeters == null
                    ? 'SYNCING DISTANCE'
                    : 'LONGEST ${JourneyFormat.distance(longestMeters).toUpperCase()}',
                style: AppTextStyles.bodySmall,
              ),
              Text('$thisMonth THIS MONTH', style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// "128 km travelled", with the numeral in the Home stat card's numeral
/// style and the unit/word as a caption beside it.
class _DistanceHeadline extends StatelessWidget {
  const _DistanceHeadline({required this.meters});

  final double meters;

  @override
  Widget build(BuildContext context) {
    final parts = JourneyFormat.distance(meters).split(' ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(parts.first, style: AppTextStyles.statNumeralCard),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${parts.length > 1 ? parts[1] : ''} travelled',
            style: AppTextStyles.chipLabel,
          ),
        ),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count == 1 ? '1 Trip' : '$count Trips',
        style: AppTextStyles.buttonLabel,
      ),
    );
  }
}
