import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_calendar.dart';

/// "M T W T F S S" above the month grid.
class PlanDateWeekdays extends StatelessWidget {
  const PlanDateWeekdays({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        for (final letter in PlanCalendar.weekdayLetters)
          Expanded(
            child: SizedBox(
              height: 28,
              child: Center(
                child: Text(letter, style: AppTypeScale.sectionLabel),
              ),
            ),
          ),
      ],
    ),
  );
}

/// One month as a grid of day buttons. Days outside [first] to [last] are
/// greyed and can't be picked; today has a ring; the picked day is filled.
class PlanDateMonth extends StatelessWidget {
  const PlanDateMonth({
    super.key,
    required this.month,
    required this.first,
    required this.last,
    required this.selected,
    required this.onPick,
  });

  /// Each day button is this tall (and at least this wide).
  static const cell = 44.0;

  final DateTime month;
  final DateTime first;
  final DateTime last;
  final DateTime? selected;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final days = PlanCalendar.grid(month);
    final today = PlanCalendar.dateOnly(DateTime.now());
    return Column(
      children: [
        for (var row = 0; row < days.length ~/ 7; row++)
          SizedBox(
            height: cell,
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _Day(
                      date: days[row * 7 + col],
                      enabled: _enabled(days[row * 7 + col]),
                      isToday:
                          days[row * 7 + col] != null &&
                          PlanCalendar.sameDay(days[row * 7 + col]!, today),
                      isSelected:
                          days[row * 7 + col] != null &&
                          selected != null &&
                          PlanCalendar.sameDay(days[row * 7 + col]!, selected!),
                      onTap: onPick,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  bool _enabled(DateTime? d) =>
      d != null && !d.isBefore(first) && !d.isAfter(last);
}

class _Day extends StatelessWidget {
  const _Day({
    required this.date,
    required this.enabled,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime? date;
  final bool enabled;
  final bool isToday;
  final bool isSelected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final d = date;
    if (d == null) return const SizedBox.shrink();
    final color = isSelected
        ? AppColors.accentForeground
        : !enabled
        ? AppColors.lockedStroke
        : isToday
        ? AppColors.accent
        : AppColors.foreground;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: isSelected,
      label: PlanCalendar.spoken(d),
      excludeSemantics: true,
      child: Center(
        child: InkResponse(
          onTap: enabled ? () => onTap(d) : null,
          radius: 22,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.accent, width: 1.5)
                  : null,
            ),
            child: Text(
              '${d.day}',
              style: TextStyle(
                fontFamily: AppTypeScale.family,
                fontSize: 14,
                fontWeight: isSelected || isToday
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
