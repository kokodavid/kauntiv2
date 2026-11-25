import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/plan_detail.dart';
import '../application/plan_editor.dart';
import '../domain/plan_day.dart';
import '../domain/plan_labels.dart';
import '../domain/trip_plan.dart';
import 'plan_day_colors.dart';
import 'plan_edit_sheets.dart';
import 'plan_pick_rows.dart';
import 'plan_sheet_frame.dart';

/// What was picked in the "Add … to" sheet: a day, or a new one.
class PlanDayChoice {
  const PlanDayChoice.day(PlanDay this.day);
  const PlanDayChoice.newDay() : day = null;

  final PlanDay? day;
  bool get isNewDay => day == null;
}

/// "Add Lake Elementaita to" or "Move to" (design): each day with its colour, date and
/// where the place will land, then "New day".
Future<PlanDayChoice?> showPlanPickDaySheet(
  BuildContext context,
  TripPlan plan, {
  required String title,
  String subtitle =
      'Pick a day. It goes in as the last stop; you can reorder after.',
  String? exceptDayId,
  bool canAddDay = true,
}) => showPlanSheet<PlanDayChoice>(
  context,
  (sheet) => PlanSheetFrame(
    title: title,
    subtitle: subtitle,
    children: [
      const SizedBox(height: 12),
      for (final day in plan.days)
        if (day.id != exceptDayId)
          PlanPickRow(
            leading: PlanPickRow.dot(PlanDayColors.of(day.number)),
            title: planDayTitle(plan, day),
            detail: planDayLanding(day),
            onTap: () => Navigator.of(sheet).pop(PlanDayChoice.day(day)),
          ),
      if (canAddDay)
        PlanPickLinkRow(
          label: 'New day (Day ${plan.days.length + 1})',
          onTap: () => Navigator.of(sheet).pop(const PlanDayChoice.newDay()),
        ),
    ],
  ),
);

/// "Day 1 · Sat 14 Nov".
String planDayTitle(TripPlan plan, PlanDay day) {
  final date = plan.dateOf(day);
  final name = 'Day ${day.number}';
  return date == null ? name : '$name · ${PlanLabels.day(date)}';
}

/// "Goes in as stop 3, after Thomson's Falls".
String planDayLanding(PlanDay day) {
  if (day.stops.isEmpty) return 'Goes in as stop 1';
  return 'Goes in as stop ${day.stops.length + 1}, '
      'after ${day.stops.last.place.name}';
}

/// Adds a day at the end and returns it once the plan shows it.
Future<PlanDay?> addPlanDay(
  BuildContext context,
  WidgetRef ref,
  TripPlan plan,
) async {
  final failure = await ref.read(planEditorProvider).addDay(plan.id);
  if (failure != null) {
    if (context.mounted) reportPlanFailure(context, failure);
    return null;
  }
  final days = ref.read(planDetailProvider(plan.id)).value?.plan.days;
  return days != null && days.length > plan.days.length ? days.last : null;
}
