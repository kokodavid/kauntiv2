import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_counties.dart';
import '../domain/plan_day.dart';
import '../domain/plan_day_path.dart';
import '../domain/plan_labels.dart';
import '../domain/plan_route.dart';
import '../domain/trip_plan.dart';
import 'plan_day_colors.dart';
import 'plan_stop_row.dart';

/// One day of the plan (design 3b, 3c): a header that folds the day, then
/// its start, stops in order, tonight's stay and the road line.
class PlanDaySection extends StatelessWidget {
  const PlanDaySection({
    super.key,
    required this.plan,
    required this.day,
    required this.route,
    required this.collapsed,
    required this.onToggle,
    required this.onRetryRoute,
    required this.claimed,
    this.homeCode,
    this.onOpenPlace,
  });

  final TripPlan plan;
  final PlanDay day;

  /// The road for this day: loading, worked out, or failed.
  final AsyncValue<PlanRoute?> route;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback onRetryRoute;
  final Set<int> claimed;
  final int? homeCode;
  final OpenPlanPlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final color = PlanDayColors.of(day.number);
    final date = plan.dateOf(day);
    final worked = route.value;
    final distance =
        worked?.distanceM ?? (day.hasFreshRoute ? day.distanceM : null);
    final duration =
        worked?.durationS ?? (day.hasFreshRoute ? day.durationS : null);
    final summary = [
      day.stops.length == 1 ? '1 stop' : '${day.stops.length} stops',
      if (distance != null) PlanLabels.distance(distance),
      if (duration != null) PlanLabels.drive(duration),
    ].join(' · ');
    final counties = PlanCounties.of(
      PlanDayPath.counties(day),
      claimed: claimed,
      homeCode: homeCode,
    );
    final countiesLine = PlanLabels.counties(
      counties.length,
      counties.where((c) => c.isNew).length,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.exploreSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.exploreBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: !collapsed,
            label: '${day.displayTitle}, $summary',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${day.number}',
                          style: AppTypeScale.itemTitle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date == null
                                  ? day.displayTitle
                                  : '${day.displayTitle} · ${PlanLabels.day(date)}',
                              style: AppTypeScale.itemTitle,
                            ),
                            Text(summary, style: AppTypeScale.meta),
                          ],
                        ),
                      ),
                      Icon(
                        collapsed ? Icons.expand_more : Icons.expand_less,
                        color: AppColors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!collapsed) ...[
            const Divider(height: 1, color: AppColors.exploreBorder),
            if (day.number == 1)
              _EndpointRow(label: 'Start · ${plan.start.displayLabel}'),
            if (day.stops.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Text(
                  'No stops on this day yet.',
                  style: AppTypeScale.small,
                ),
              )
            else
              for (var i = 0; i < day.stops.length; i++)
                PlanStopRow(
                  stop: day.stops[i],
                  number: i + 1,
                  color: color,
                  isLast: i == day.stops.length - 1 && !day.hasOvernight,
                  locked: plan.limits.isStopLocked(i),
                  showAddedBy: plan.isShared,
                  onOpenPlace: onOpenPlace,
                ),
            if (day.hasOvernight)
              _EndpointRow(
                label:
                    'Stay · ${day.overnightPlace?.name ?? day.overnightLabel ?? 'Chosen point'}',
              ),
            _RouteLine(route: route, onRetry: onRetryRoute),
            if (countiesLine != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(countiesLine, style: AppTypeScale.meta),
              ),
          ],
        ],
      ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
    child: Row(
      children: [
        const Icon(
          Icons.flag_outlined,
          size: 18,
          color: AppColors.mutedForeground,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTypeScale.small)),
      ],
    ),
  );
}

/// Whether the road for the day is loading, worked out, or failed. The
/// stops stay whatever happens here.
class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.route, required this.onRetry});

  final AsyncValue<PlanRoute?> route;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (route.isLoading && !route.hasValue) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          key: const ValueKey('route-skeleton'),
          height: 14,
          width: 180,
          decoration: BoxDecoration(
            color: AppColors.lockedFill,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      );
    }
    if (route.hasError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                "Couldn't work out the road. Your stops are safe.",
                style: AppTypeScale.small,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final worked = route.value;
    if (worked == null) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        '${PlanLabels.distance(worked.distanceM)} by road · '
        '${PlanLabels.drive(worked.durationS)} · estimate',
        style: AppTypeScale.meta,
      ),
    );
  }
}
