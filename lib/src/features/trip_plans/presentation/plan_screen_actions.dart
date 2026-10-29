import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../application/plan_editor.dart';
import '../domain/plan_day.dart';
import '../domain/plan_failure.dart';
import '../domain/trip_plan.dart';
import 'add_places_page.dart';
import 'plan_day_parts.dart';
import 'plan_edit_sheets.dart';
import 'plan_menu.dart';
import 'plan_stop_menu.dart';
import 'plan_stop_row.dart';

/// What the plan screen does when someone edits (design 3d to 3g): asks
/// for what's needed (a name, a day, a date), makes the change through
/// [PlanEditor], and says why when it was refused.
class PlanScreenActions {
  PlanScreenActions(this.context, this.ref, this.plan, {this.onGone});

  final BuildContext context;
  final WidgetRef ref;
  final TripPlan plan;

  /// The plan is deleted or archived: leave its screen.
  final VoidCallback? onGone;

  PlanEditor get _editor => ref.read(planEditorProvider);

  Future<void> _report(Future<PlanFailure?> change) async {
    final failure = await change;
    if (failure != null && context.mounted) {
      reportPlanFailure(context, failure);
    }
  }

  PlanDayActions forDay(PlanDay day) => PlanDayActions(
    canMoveStopsToDay: plan.days.length > 1,
    onStop: (index, action) => _stop(day, index, action),
    onRenameDay: () => _renameDay(day),
    onAddPlaces: () => unawaited(addPlaces(day: day)),
    onRemoveDay: plan.days.length > 1 ? () => _removeDay(day) : null,
    onAddFromPlaces: plan.places.isEmpty ? null : () => _addIdea(day),
  );

  Future<void> _stop(PlanDay day, int index, PlanStopAction action) async {
    final stop = day.stops[index];
    switch (action) {
      case PlanStopAction.up:
        await _report(_editor.nudgeStop(plan.id, day, index, -1));
      case PlanStopAction.down:
        await _report(_editor.nudgeStop(plan.id, day, index, 1));
      case PlanStopAction.moveToDay:
        final target = await _pickDay(day);
        if (target != null) {
          await _report(_editor.moveStopToDay(plan.id, stop.id, target.id));
        }
      case PlanStopAction.note:
        final note = await showPlanTextInput(
          context,
          title: 'Note for ${stop.place.name}',
          initial: stop.note,
          hint: 'Book ahead, bring a jacket…',
          maxLength: 200,
          allowEmpty: true,
        );
        if (note != null) {
          await _report(_editor.setNote(plan.id, stop.id, note));
        }
      case PlanStopAction.toPlaces:
        await _report(_editor.removeStop(plan.id, stop.id, toPlacesList: true));
      case PlanStopAction.remove:
        await _report(_editor.removeStop(plan.id, stop.id));
    }
  }

  Future<void> _renameDay(PlanDay day) async {
    final title = await showPlanTextInput(
      context,
      title: 'Name this day',
      initial: day.title,
      hint: 'Day ${day.number}',
      maxLength: 40,
      allowEmpty: true,
    );
    if (title != null) await _report(_editor.renameDay(plan.id, day.id, title));
  }

  Future<void> _removeDay(PlanDay day) async {
    final ok = await showPlanConfirm(
      context,
      title: 'Remove ${day.displayTitle}?',
      message: day.stops.isEmpty
          ? 'The day is empty.'
          : 'Its ${day.stops.length} stops will be taken off the plan.',
      action: 'Remove',
    );
    if (ok) await _report(_editor.removeDay(plan.id, day.id));
  }

  Future<void> _addIdea(PlanDay day) async {
    final idea = await _pick<PlanIdea>(
      'Add to ${day.displayTitle}',
      plan.places,
      (i) => i.place.name,
      (i) => planPlaceMeta(i.place.type, i.place.countyCode),
    );
    if (idea != null) {
      await _report(_editor.addIdeaToDay(plan.id, day.id, idea.place.id));
    }
  }

  Future<PlanDay?> _pickDay(PlanDay from) => _pick<PlanDay>(
    'Move to',
    [
      for (final d in plan.days)
        if (d.id != from.id) d,
    ],
    (d) => d.displayTitle,
    (d) => d.stops.length == 1 ? '1 stop' : '${d.stops.length} stops',
  );

  Future<T?> _pick<T>(
    String title,
    List<T> items,
    String Function(T) label,
    String Function(T) detail,
  ) => showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheet).height * 0.6,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(title, style: AppTypeScale.sectionTitle),
            ),
            for (final item in items)
              ListTile(
                minTileHeight: 56,
                title: Text(label(item)),
                subtitle: Text(detail(item)),
                onTap: () => Navigator.of(sheet).pop(item),
              ),
          ],
        ),
      ),
    ),
  );

  /// Add places: onto [day], or onto Places to visit when [day] is null.
  Future<void> addPlaces({PlanDay? day}) async {
    final taken = {
      for (final d in plan.days)
        for (final s in d.stops) s.place.id,
      for (final idea in plan.places) idea.place.id,
    };
    await showAddPlacesPage(
      context,
      title: day == null
          ? 'Add to Places to visit'
          : 'Add to ${day.displayTitle}',
      alreadyIn: taken,
      onAdd: (place) async {
        final PlanFailure? failure;
        if (day == null) {
          failure = await _editor.addToList(plan.id, place.id);
        } else {
          failure = (await _editor.addStop(plan.id, day.id, place.id)).$1;
        }
        if (failure != null && context.mounted) {
          reportPlanFailure(context, failure);
        }
        return failure == null;
      },
    );
  }

  Future<void> addDay() => _report(_editor.addDay(plan.id));

  Future<void> planMenu(PlanMenuAction action) async {
    switch (action) {
      case PlanMenuAction.rename:
        final title = await showPlanTextInput(
          context,
          title: 'Rename plan',
          initial: plan.title,
          maxLength: 60,
        );
        if (title != null) await _report(_editor.rename(plan.id, title));
      case PlanMenuAction.dates:
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: plan.startDate ?? now,
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: now.add(const Duration(days: 730)),
          helpText: 'Day 1 is on',
        );
        if (date != null) await _report(_editor.setStartDate(plan.id, date));
      case PlanMenuAction.archive:
        final ok = await showPlanConfirm(
          context,
          title: 'Archive this plan?',
          message: 'It stops counting toward your upcoming plans.',
          action: 'Archive',
        );
        if (!ok) return;
        final failure = await _editor.archive(plan.id);
        if (failure != null && context.mounted) {
          reportPlanFailure(context, failure);
        } else {
          onGone?.call();
        }
      case PlanMenuAction.delete:
        final ok = await showPlanConfirm(
          context,
          title: 'Delete this plan?',
          message: 'It is removed for everyone on it. This can\'t be undone.',
          action: 'Delete',
        );
        if (!ok) return;
        final failure = await _editor.delete(plan.id);
        if (failure != null && context.mounted) {
          reportPlanFailure(context, failure);
        } else {
          if (context.mounted) {
            showAppToast(
              context,
              variant: AppToastVariant.neutral,
              title: 'Plan deleted',
            );
          }
          onGone?.call();
        }
    }
  }
}
