import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_calendar.dart';
import 'plan_date_month.dart';
import 'plan_sheet_frame.dart';

/// Picks a date in a bottom sheet that matches the rest of the planner.
/// Returns the date, or null when the user closes the sheet. Days before
/// [first] and after [last] are greyed out.
Future<DateTime?> showPlanDateSheet(
  BuildContext context, {
  required String title,
  required DateTime first,
  required DateTime last,
  DateTime? selected,
}) => showPlanSheet<DateTime>(
  context,
  (_) => PlanDatePickerSheet(
    title: title,
    first: PlanCalendar.dateOnly(first),
    last: PlanCalendar.dateOnly(last),
    selected: selected == null ? null : PlanCalendar.dateOnly(selected),
  ),
);

class PlanDatePickerSheet extends StatefulWidget {
  const PlanDatePickerSheet({
    super.key,
    required this.title,
    required this.first,
    required this.last,
    this.selected,
  });

  final String title;
  final DateTime first;
  final DateTime last;
  final DateTime? selected;

  @override
  State<PlanDatePickerSheet> createState() => _PlanDatePickerSheetState();
}

class _PlanDatePickerSheetState extends State<PlanDatePickerSheet> {
  late final List<DateTime> _months = PlanCalendar.months(
    widget.first,
    widget.last,
  );
  late final PageController _pages = PageController(initialPage: _startPage);
  late int _page = _startPage;
  late DateTime? _picked = widget.selected;

  int get _startPage {
    final near = widget.selected ?? widget.first;
    final index = _months.indexWhere(
      (m) => m.year == near.year && m.month == near.month,
    );
    return index < 0 ? 0 : index;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeInOut,
  );

  @override
  Widget build(BuildContext context) {
    final month = _months[_page];
    return PlanSheetFrame(
      title: widget.title,
      children: [
        Row(
          children: [
            _Arrow(
              icon: Icons.chevron_left,
              tooltip: 'Previous month',
              onTap: _page > 0 ? () => _go(_page - 1) : null,
            ),
            Expanded(
              child: Text(
                '${PlanCalendar.monthNames[month.month - 1]} ${month.year}',
                textAlign: TextAlign.center,
                style: AppTypeScale.itemTitle,
              ),
            ),
            _Arrow(
              icon: Icons.chevron_right,
              tooltip: 'Next month',
              onTap: _page < _months.length - 1 ? () => _go(_page + 1) : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const PlanDateWeekdays(),
        SizedBox(
          height: PlanDateMonth.cell * 6,
          child: PageView.builder(
            controller: _pages,
            itemCount: _months.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, i) => PlanDateMonth(
              month: _months[i],
              first: widget.first,
              last: widget.last,
              selected: _picked,
              onPick: (d) => setState(() => _picked = d),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.accentForeground,
              disabledBackgroundColor: AppColors.segmentedTrack,
              disabledForegroundColor: AppColors.faintForeground,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: AppTypeScale.family,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: _picked == null
                ? null
                : () => Navigator.of(context).pop(_picked),
            child: Text(
              _picked == null
                  ? 'Pick a day'
                  : 'Set ${PlanCalendar.weekdayNames[_picked!.weekday - 1].substring(0, 3)} '
                        '${_picked!.day} '
                        '${PlanCalendar.monthNames[_picked!.month - 1].substring(0, 3)}',
            ),
          ),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    color: AppColors.foreground,
    disabledColor: AppColors.lockedStroke,
    onPressed: onTap,
    icon: Icon(icon),
  );
}
