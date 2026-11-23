import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaunti47_v2/src/features/trip_plans/presentation/planned_view.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/plan_detail.dart';
import '../application/plan_editor.dart';
import '../application/plan_places_providers.dart';
import '../application/planned_trips_list.dart';
import '../application/trip_plans_providers.dart';
import '../domain/plan_failure.dart';
import '../domain/plan_labels.dart';
import '../domain/trip_plan.dart';
import '../domain/trip_plan_summary.dart';
import 'plan_day_colors.dart';
import 'plan_edit_sheets.dart';
import 'plan_pick_day_sheet.dart';
import 'plan_pick_rows.dart';
import 'plan_sheet_frame.dart';
import 'start_plan_trip.dart';

/// "Add to trip" from a place (design 5a to 5c): pick a plan, then a day or
/// Places to visit. Says what happened in a toast with Undo.
Future<void> showAddToTrip(
  BuildContext context,
  WidgetRef ref, {
  required String placeId,
  required String placeName,
  OpenTripPlan? onOpenPlan,
}) async {
  final picked = await showPlanSheet<_Added>(
    context,
    (_) => _AddToTripSheet(placeId: placeId, placeName: placeName),
  );
  if (!context.mounted) return;
  if (picked == null) return;
  if (picked.newPlan) {
    await startPlanTrip(
      context,
      ref,
      firstPlaceId: placeId,
      onOpenPlan: onOpenPlan,
    );
    ref.invalidate(placeTripsProvider(placeId));
    return;
  }
  ref.invalidate(placeTripsProvider(placeId));
  showAppToast(
    context,
    variant: AppToastVariant.success,
    title: 'Added to ${picked.planTitle}',
    message: picked.where,
    actionLabel: 'Undo',
    onAction: () => unawaited(_undo(ref, picked, placeId)),
  );
}

/// Takes the place back off. Uses the caller's [ref], which outlives the
/// sheet; a lost connection just leaves the place where it was.
Future<void> _undo(WidgetRef ref, _Added added, String placeId) async {
  try {
    final repository = ref.read(tripPlansRepositoryProvider);
    final stopId = added.stopId;
    if (stopId != null) {
      await repository?.removeStop(stopId);
    } else {
      await repository?.removePlace(added.planId, placeId);
    }
    await ref.read(plannedTripsListProvider.notifier).refresh();
    await ref.read(planDetailProvider(added.planId).notifier).refresh();
    ref.invalidate(placeTripsProvider(placeId));
  } on Object {
    // Off the page, or offline: the place stays where it was.
  }
}

class _Added {
  const _Added.newPlan()
    : newPlan = true,
      planId = '',
      planTitle = '',
      where = null,
      stopId = null;

  const _Added({
    required this.planId,
    required this.planTitle,
    required this.where,
    required this.stopId,
  }) : newPlan = false;

  final bool newPlan;
  final String planId;
  final String planTitle;
  final String? where;

  /// Set when it went onto a day; null when onto Places to visit.
  final String? stopId;
}

class _AddToTripSheet extends ConsumerStatefulWidget {
  const _AddToTripSheet({required this.placeId, required this.placeName});

  final String placeId;
  final String placeName;

  @override
  ConsumerState<_AddToTripSheet> createState() => _AddToTripSheetState();
}

class _AddToTripSheetState extends ConsumerState<_AddToTripSheet> {
  TripPlanSummary? _chosen;
  Future<TripPlan>? _plan;
  bool _busy = false;

  Future<void> _choose(TripPlanSummary summary) async {
    final repository = ref.read(tripPlansRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _chosen = summary;
      _plan = repository.get(summary.id);
    });
  }

  Future<void> _add(TripPlan plan, {String? dayId, String? dayLabel}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final editor = ref.read(planEditorProvider);
    PlanFailure? failure;
    String? stopId;
    if (dayId == null) {
      failure = await editor.addToList(plan.id, widget.placeId);
    } else {
      (failure, stopId) = await editor.addStop(plan.id, dayId, widget.placeId);
    }
    if (!mounted) return;
    if (failure != null) {
      setState(() => _busy = false);
      reportPlanFailure(context, failure);
      return;
    }
    Navigator.of(context).pop(
      _Added(
        planId: plan.id,
        planTitle: plan.title,
        where: dayLabel ?? 'Places to visit',
        stopId: stopId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
    ),
    child: _chosen == null ? _plans() : _days(),
  );

  Widget _plans() {
    final list = ref.watch(plannedTripsListProvider).value;
    final here =
        ref.watch(placeTripsProvider(widget.placeId)).value ?? const [];
    final heldIds = {for (final p in here) p.id};
    final plans = [
      ...?list?.plans.upcoming,
      ...?list?.plans.shared.where((p) => p.role.canEdit),
    ];
    return PlanSheetFrame(
      title: 'Add ${widget.placeName} to',
      subtitle: 'Pick a trip, then a day or Places to visit.',
      children: [
        if (list == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: AppProgressIndicator()),
          ),
        for (final plan in plans)
          PlanPickRow(
            title: plan.title,
            detail: heldIds.contains(plan.id)
                ? 'Already in this plan'
                : [
                    PlanLabels.days(plan.days.length),
                    if (plan.startDate != null) PlanLabels.day(plan.startDate!),
                  ].join(' · '),
            trailing: Icon(
              heldIds.contains(plan.id)
                  ? Icons.check_circle
                  : Icons.chevron_right,
              size: 20,
              color: heldIds.contains(plan.id)
                  ? AppColors.accent
                  : AppColors.faintForeground,
            ),
            onTap: heldIds.contains(plan.id)
                ? null
                : () => unawaited(_choose(plan)),
          ),
        PlanPickLinkRow(
          label: 'New plan with this place',
          icon: Icons.add_circle_outline,
          onTap: () => Navigator.of(context).pop(const _Added.newPlan()),
        ),
      ],
    );
  }

  Widget _days() => FutureBuilder<TripPlan>(
    future: _plan,
    builder: (context, snapshot) {
      final plan = snapshot.data;
      return PlanSheetFrame(
        title: _chosen!.title,
        subtitle: 'Pick a day. It goes in as the last stop.',
        onBack: () => setState(() => _chosen = null),
        children: [
          if (snapshot.hasError)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text("Couldn't open this plan. Try again."),
            )
          else if (plan == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: AppProgressIndicator()),
            )
          else ...[
            for (final day in plan.days)
              PlanPickRow(
                leading: PlanPickRow.dot(PlanDayColors.of(day.number)),
                title: planDayTitle(plan, day),
                detail: plan.limits.canAddStop(day.stops.length)
                    ? planDayLanding(day)
                    : 'This day is full',
                onTap: _busy || !plan.limits.canAddStop(day.stops.length)
                    ? null
                    : () => unawaited(
                        _add(plan, dayId: day.id, dayLabel: day.displayTitle),
                      ),
              ),
            PlanPickLinkRow(
              label: 'Places to visit (not on a day yet)',
              icon: Icons.bookmark_border,
              onTap: _busy ? null : () => unawaited(_add(plan)),
            ),
          ],
        ],
      );
    },
  );
}
