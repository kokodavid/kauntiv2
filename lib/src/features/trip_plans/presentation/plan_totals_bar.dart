import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_counties.dart';
import '../domain/plan_labels.dart';
import '../domain/plan_totals.dart';

/// The numbers over the days (design 3a): stops, road and time (always an
/// estimate), and the counties the plan passes through.
class PlanTotalsBar extends StatelessWidget {
  const PlanTotalsBar({
    super.key,
    required this.totals,
    required this.claimed,
    this.homeCode,
  });

  final PlanTotals totals;
  final Set<int> claimed;
  final int? homeCode;

  @override
  Widget build(BuildContext context) {
    final counties = PlanCounties.of(
      totals.countyCodes,
      claimed: claimed,
      homeCode: homeCode,
    );
    final line = PlanLabels.counties(
      counties.length,
      counties.where((c) => c.isNew).length,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.exploreSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.exploreBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stat(
                label: 'Stops',
                value: '${totals.stops}',
              ),
              _Stat(
                label: 'By road',
                value: totals.hasRoute
                    ? PlanLabels.distance(totals.distanceM)
                    : '–',
              ),
              _Stat(
                label: 'Driving',
                value: totals.hasRoute ? PlanLabels.drive(totals.durationS) : '–',
              ),
            ],
          ),
          if (totals.hasRoute)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Road and driving time are estimates.',
                style: AppTypeScale.meta,
              ),
            ),
          if (totals.pending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                totals.pending == 1
                    ? 'One day is still being worked out.'
                    : '${totals.pending} days are still being worked out.',
                style: AppTypeScale.meta,
              ),
            ),
          if (line != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(line, style: AppTypeScale.small),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypeScale.cardTitle),
        Text(label, style: AppTypeScale.meta),
      ],
    ),
  );
}
