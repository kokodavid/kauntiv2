import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_counties.dart';
import '../domain/plan_labels.dart';
import '../domain/plan_totals.dart';

/// The numbers over the days (design 3a): days, distance, drive time (always
/// an estimate) and the counties the plan passes through, with how many of
/// them are new.
class PlanTotalsBar extends StatelessWidget {
  const PlanTotalsBar({
    super.key,
    required this.totals,
    required this.days,
    required this.claimed,
    this.homeCode,
  });

  final PlanTotals totals;
  final int days;
  final Set<int> claimed;
  final int? homeCode;

  @override
  Widget build(BuildContext context) {
    final counties = PlanCounties.of(
      totals.countyCodes,
      claimed: claimed,
      homeCode: homeCode,
    );
    final fresh = counties.where((c) => c.isNew).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.exploreSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.exploreBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                _Stat(value: Text('$days'), label: days == 1 ? 'Day' : 'Days'),
                const _Rule(),
                _Stat(
                  value: Text(
                    totals.hasRoute ? PlanLabels.distance(totals.distanceM) : '–',
                  ),
                  label: 'Distance',
                ),
                const _Rule(),
                _Stat(
                  value: Text(
                    totals.hasRoute
                        ? PlanLabels.driveShort(totals.durationS)
                        : '–',
                  ),
                  label: 'Drive, est.',
                ),
                const _Rule(),
                _Stat(
                  value: counties.isEmpty
                      ? const Text('–')
                      : Text.rich(
                          TextSpan(
                            text: '${counties.length}',
                            children: [
                              if (fresh > 0)
                                TextSpan(
                                  text: ' · $fresh new',
                                  style: const TextStyle(
                                    color: AppColors.newCountyText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                  label: counties.length == 1 ? 'County' : 'Counties',
                ),
              ],
            ),
          ),
          if (totals.pending > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                totals.pending == 1
                    ? 'One day is still being worked out.'
                    : '${totals.pending} days are still being worked out.',
                style: AppTypeScale.meta,
              ),
            ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 14),
    child: VerticalDivider(width: 1, color: AppColors.exploreBorder),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final Widget value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 6, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultTextStyle.merge(
            style: AppTypeScale.cardTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: value,
          ),
          Text(label, style: AppTypeScale.meta),
        ],
      ),
    ),
  );
}
