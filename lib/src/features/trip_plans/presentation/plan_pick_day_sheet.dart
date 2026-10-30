import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/plan_detail.dart';
import '../application/plan_editor.dart';
import '../domain/plan_day.dart';
import '../domain/plan_labels.dart';
import '../domain/trip_plan.dart';
import 'plan_day_colors.dart';
import 'plan_edit_sheets.dart';
import 'plan_sheet_frame.dart';

/// What was picked in the "Add … to" sheet: a day, or a new one.
class PlanDayChoice {
  const PlanDayChoice.day(PlanDay this.day);
  const PlanDayChoice.newDay() : day = null;

  final PlanDay? day;
  bool get isNewDay => day == null;
}

/// "Add Lake Elementaita to" (design): each day with its colour, date and
/// where the place will land, then "New day".
Future<PlanDayChoice?> showPlanPickDaySheet(
  BuildContext context,
  TripPlan plan, {
  required String placeName,
  bool canAddDay = true,
}) => showPlanSheet<PlanDayChoice>(
  context,
  (sheet) => PlanSheetFrame(
    title: 'Add $placeName to',
    subtitle: 'Pick a day. It goes in as the last stop; you can reorder after.',
    children: [
      const SizedBox(height: 12),
      for (final day in plan.days)
        _DayRow(
          color: PlanDayColors.of(day.number),
          title: _title(plan, day),
          detail: _detail(day),
          onTap: () => Navigator.of(sheet).pop(PlanDayChoice.day(day)),
        ),
      if (canAddDay)
        _NewDayRow(
          label: 'New day (Day ${plan.days.length + 1})',
          onTap: () => Navigator.of(sheet).pop(const PlanDayChoice.newDay()),
        ),
    ],
  ),
);

String _title(TripPlan plan, PlanDay day) {
  final date = plan.dateOf(day);
  final name = 'Day ${day.number}';
  return date == null ? name : '$name · ${PlanLabels.day(date)}';
}

String _detail(PlanDay day) {
  if (day.stops.isEmpty) return 'Goes in as stop 1';
  return 'Goes in as stop ${day.stops.length + 1}, '
      'after ${day.stops.last.place.name}';
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.color,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final Color color;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.exploreBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypeScale.itemTitle),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: AppTypeScale.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _NewDayRow extends StatelessWidget {
  const _NewDayRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.exploreBorder)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Text(
            label,
            style: AppTypeScale.action.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    ),
  );
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
