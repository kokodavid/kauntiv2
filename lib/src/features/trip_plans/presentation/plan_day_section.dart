import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_counties.dart';
import '../domain/plan_day_recording.dart';
import '../domain/plan_day.dart';
import '../domain/plan_day_path.dart';
import '../domain/plan_labels.dart';
import '../domain/plan_route.dart';
import '../domain/trip_plan.dart';
import 'plan_day_colors.dart';
import 'plan_day_parts.dart';
import 'plan_stop_menu.dart';
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
                      if (actions != null)
                        PopupMenuButton<bool>(
                          tooltip: 'Day options',
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          icon: const Icon(
                            Icons.more_horiz,
                            color: AppColors.mutedForeground,
                          ),
                          onSelected: (rename) => rename
                              ? actions!.onRenameDay()
                              : actions!.onRemoveDay?.call(),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: true,
                              child: Text('Rename day'),
                            ),
                            if (actions!.onRemoveDay != null)
                              const PopupMenuItem(
                                value: false,
                                child: Text('Remove day'),
                              ),
                          ],
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
              for (var i = 0; i < day.stops.length; i++)
                PlanStopRow(
                  stop: day.stops[i],
                  number: i + 1,
                  color: color,
                  isLast: i == day.stops.length - 1 && !day.hasOvernight,
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
                          onSelected: (action) => actions!.onStop(i, action),
                        ),
                ),
            if (day.hasOvernight)
              PlanEndpointRow(
                label:
                    'Stay · ${day.overnightPlace?.name ?? day.overnightLabel ?? 'Chosen point'}',
              ),
            if (actions != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Wrap(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                      ),
                      onPressed: actions!.onAddPlaces,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add a place'),
                    ),
                    if (actions!.onAddFromPlaces != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                        ),
                        onPressed: actions!.onAddFromPlaces,
                        child: const Text('From Places to visit'),
                      ),
                  ],
                ),
              ),
            PlanRouteLine(route: route, onRetry: onRetryRoute),
            if (recording != null)
              PlanRecordedRow(
                recording: recording!,
                onWatchReplay: onWatchReplay == null
                    ? null
                    : () => onWatchReplay!(recording!.journeyId),
              ),
            if (onStart != null && day.stops.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      recording == null ? 'Start trip' : 'Record again',
                    ),
                  ),
                ),
              ),
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
