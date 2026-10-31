import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../application/plan_editor.dart';
import '../application/trip_plans_providers.dart';
import '../domain/plan_counties.dart';
import '../domain/plan_day.dart';
import '../domain/plan_failure.dart';
import '../domain/trip_plan.dart';
import 'add_places_page.dart';
import 'plan_archive_actions.dart';
import 'plan_best_order_actions.dart';
import 'plan_date_picker_sheet.dart';
import 'plan_day_parts.dart';
import 'plan_edit_sheets.dart';
import 'plan_day_colors.dart';
import 'plan_menu.dart';
import 'plan_pick_day_sheet.dart';
import 'plan_pick_idea_sheet.dart';
import 'plan_remove_confirms.dart';
import 'plan_note_sheet.dart';
import 'plan_stop_menu.dart';

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
    onBestOrder: day.stops.length >= 3
        ? () => unawaited(PlanBestOrderActions(context, ref, plan).run(day))
        : null,
    bestOrderIsPro: !plan.limits.bestOrder,
  );

  Future<void> _stop(PlanDay day, int index, PlanStopAction action) async {
    final stop = day.stops[index];
    switch (action) {
      case PlanStopAction.up:
        await _report(_editor.nudgeStop(plan.id, day, index, -1));
      case PlanStopAction.down:
        await _report(_editor.nudgeStop(plan.id, day, index, 1));
      case PlanStopAction.open:
        break; // the day card opens places
      case PlanStopAction.moveToDay:
        final target = await _pickDay(day);
        if (target != null) {
          await _report(_editor.moveStopToDay(plan.id, stop.id, target.id));
        }
      case PlanStopAction.note:
        final claimed =
            ref.read(planClaimedCountyCodesProvider).value ?? const <int>{};
        final note = await showPlanNoteSheet(
          context,
          stop: stop,
          number: index + 1,
          color: PlanDayColors.of(day.number),
          dayLabel: 'Day ${day.number}',
          countyStatus: PlanCounties.of(
            [stop.place.countyCode],
            claimed: claimed,
          ).first.status,
        );
        if (note != null) {
          await _report(_editor.setNote(plan.id, stop.id, note));
        }
      case PlanStopAction.toPlaces:
        if (await PlanRemoveConfirms.stopToPlaces(context, day, stop)) {
          await _report(
            _editor.removeStop(plan.id, stop.id, toPlacesList: true),
          );
        }
      case PlanStopAction.remove:
        if (await PlanRemoveConfirms.stopFromPlan(context, day, stop)) {
          await _report(_editor.removeStop(plan.id, stop.id));
        }
    }
  }

  Future<void> _renameDay(PlanDay day) async {
    final title = await showPlanTextInput(
      context,
      title: 'Name this day', label: 'Day name',
      initial: day.title,
      hint: 'Day ${day.number}',
      maxLength: 40,
      allowEmpty: true,
    );
    if (title != null) await _report(_editor.renameDay(plan.id, day.id, title));
  }

  Future<void> _removeDay(PlanDay day) async {
    final ok = await PlanRemoveConfirms.day(
      context,
      day,
      laterDays: day.number < plan.days.length,
    );
    if (ok) await _report(_editor.removeDay(plan.id, day.id));
  }

  Future<void> _addIdea(PlanDay day) async {
    final idea = await showPlanPickIdeaSheet(context, plan, day);
    if (idea != null) {
      await _report(_editor.addIdeaToDay(plan.id, day.id, idea.place.id));
    }
  }

  /// "Add to Day…" on a Places to visit card: straight onto the only day,
  /// or after asking which (or for a new one).
  Future<void> addIdeaToDay(PlanIdea idea) async {
    var day = plan.days.length == 1 ? plan.days.first : null;
    if (day == null) {
      final choice = await showPlanPickDaySheet(
        context,
        plan,
        title: 'Add ${idea.place.name} to',
      );
      if (choice == null) return;
      day = choice.day ?? await addPlanDay(context, ref, plan);
    }
    if (day != null) {
      await _report(_editor.addIdeaToDay(plan.id, day.id, idea.place.id));
    }
  }

  Future<PlanDay?> _pickDay(PlanDay from) async {
    final choice = await showPlanPickDaySheet(
      context,
      plan,
      title: 'Move to',
      subtitle: 'Pick a day. It goes in as the last stop.',
      exceptDayId: from.id,
    );
    if (choice == null) return null;
    return choice.day ?? await addPlanDay(context, ref, plan);
  }

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
          title: 'Rename plan', label: 'Plan name',
          initial: plan.title,
          maxLength: 60,
        );
        if (title != null) await _report(_editor.rename(plan.id, title));
      case PlanMenuAction.dates:
        final now = DateTime.now();
        final date = await showPlanDateSheet(
          context,
          title: 'Day 1 is on',
          first: DateTime(now.year, now.month, now.day),
          last: now.add(const Duration(days: 730)),
          selected: plan.startDate,
        );
        if (date != null) await _report(_editor.setStartDate(plan.id, date));
      case PlanMenuAction.invite ||
          PlanMenuAction.people ||
          PlanMenuAction.leave ||
          PlanMenuAction.mute ||
          PlanMenuAction.unmute ||
          PlanMenuAction.keepOffline ||
          PlanMenuAction.removeOffline:
        break; // handled by PlanShareActions and PlanOfflineActions
      case PlanMenuAction.archive:
        if (await PlanArchiveActions(context, ref).archive(plan.id)) {
          onGone?.call();
        }
      case PlanMenuAction.unarchive:
        await PlanArchiveActions(context, ref).restore(plan.id);
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
