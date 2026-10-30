import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_counties.dart';
import '../domain/plan_day.dart';
import '../domain/plan_day_legs.dart';
import '../domain/plan_day_path.dart';
import '../domain/plan_day_recording.dart';
import '../domain/plan_labels.dart';
import '../domain/plan_route.dart';
import '../domain/trip_plan.dart';
import '../application/plan_directions.dart';
import 'plan_day_colors.dart';
import 'plan_day_footer.dart';
import 'plan_day_header.dart';
import 'plan_day_parts.dart';
import 'plan_day_rail.dart';
import 'plan_stop_menu.dart';
import 'plan_stop_row.dart';

/// One day of the plan (design 3a): a header that folds the day, then its
/// start, the stops in order with the road between them, tonight's stay, the
/// day's total, the counties it passes through, and the buttons.
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
    this.actions,
    this.recording,
    this.onStart,
    this.onWatchReplay,
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
  final PlanDayActions? actions;

  /// My Trip recorded for this day, if any.
  final PlanDayRecording? recording;

  /// Start trip for this day; null when it can't be started here.
  final VoidCallback? onStart;
  final void Function(String journeyId)? onWatchReplay;

  @override
  Widget build(BuildContext context) {
    final color = PlanDayColors.of(day.number);
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
    final stopStatus = {
      for (final c in PlanCounties.of(
        [for (final s in day.stops) s.place.countyCode],
        claimed: claimed,
        homeCode: homeCode,
      ))
        c.code: c.status,
    };
    final legs = PlanDayLegs.of(plan, day, worked);
    final title = day.title?.trim();
    final points = PlanDayPath.waypoints(plan, day);
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
          PlanDayHeader(
            number: day.number,
            color: color,
            date: plan.dateOf(day),
            title: title == null || title.isEmpty ? null : title,
            summary: summary,
            collapsed: collapsed,
            onToggle: onToggle,
            semanticLabel: '${day.displayTitle}, $summary',
            onRename: actions?.onRenameDay,
            onRemove: actions?.onRemoveDay,
          ),
          if (!collapsed) ...[
            if (day.number == 1)
              PlanEndpointRow(label: 'Start · ${plan.start.displayLabel}'),
            if (day.stops.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Text(
                  'No stops on this day yet.',
                  style: AppTypeScale.small,
                ),
              )
            else
              for (var i = 0; i < day.stops.length; i++) ...[
                if (legs.before(i) case final leg?) PlanLegRow(leg: leg),
                PlanStopRow(
                  stop: day.stops[i],
                  number: i + 1,
                  color: color,
                  countyStatus: stopStatus[day.stops[i].place.countyCode],
                  locked: plan.limits.isStopLocked(i),
                  showAddedBy: plan.isShared,
                  onOpenPlace: onOpenPlace,
                  menu: actions == null
                      ? null
                      : PlanStopMenu(
                          canMoveUp: i > 0,
                          canMoveDown: i < day.stops.length - 1,
                          canMoveToDay: actions!.canMoveStopsToDay,
                          hasNote: day.stops[i].note != null,
                          onSelected: (action) => _stop(context, i, action),
                        ),
                ),
              ],
            if (day.hasOvernight) ...[
              if (legs.toOvernight case final leg?) PlanLegRow(leg: leg),
              PlanEndpointRow(
                stay: true,
                last: true,
                label:
                    'Overnight · ${day.overnightPlace?.name ?? day.overnightLabel ?? 'Chosen point'}',
              ),
            ],
            const Divider(height: 1, color: AppColors.exploreBorder),
            PlanRouteLine(route: route, onRetry: onRetryRoute),
            PlanPassesThrough(counties: counties),
            if (actions != null) PlanDayLinks(actions: actions!),
            if (recording != null)
              PlanRecordedRow(
                recording: recording!,
                onWatchReplay: onWatchReplay == null
                    ? null
                    : () => onWatchReplay!(recording!.journeyId),
              ),
            PlanDayButtons(
              startLabel: recording == null ? 'Start trip' : 'Record again',
              onStart: onStart != null && day.stops.isNotEmpty ? onStart : null,
              onDirections: points.length >= 2
                  ? () => unawaited(openPlanDirections(points))
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  /// "Open place" is handled here; the rest go to the plan's editor.
  void _stop(BuildContext context, int index, PlanStopAction action) {
    if (action == PlanStopAction.open) {
      onOpenPlace?.call(context, day.stops[index].place.id);
    } else {
      actions?.onStop(index, action);
    }
  }
}
