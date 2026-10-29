import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_labels.dart';
import '../domain/plan_limits.dart';
import 'create_plan_parts.dart';

/// Start date (optional) beside the Days stepper.
class CreatePlanDateAndDays extends StatelessWidget {
  const CreatePlanDateAndDays({
    super.key,
    required this.date,
    required this.days,
    required this.maxDays,
    required this.onPickDate,
    required this.onClearDate,
    required this.onDays,
    required this.onBlockedIncrement,
  });

  final DateTime? date;
  final int days;
  final int maxDays;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final ValueChanged<int> onDays;
  final VoidCallback onBlockedIncrement;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CreatePlanLabel('Start date · optional'),
            _DateField(date: date, onTap: onPickDate, onClear: onClearDate),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CreatePlanLabel('Days'),
            CreatePlanDaysStepper(
              days: days,
              max: maxDays,
              onChanged: onDays,
              onBlockedIncrement: onBlockedIncrement,
            ),
          ],
        ),
      ),
    ],
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.exploreSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.inputBorder),
    ),
    child: InkWell(
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null ? 'Add a date' : PlanLabels.day(date!),
                style: AppTypeScale.itemTitle.copyWith(
                  fontWeight: FontWeight.w400,
                  color: date == null
                      ? AppColors.faintForeground
                      : AppColors.foreground,
                ),
              ),
            ),
            if (date != null)
              IconButton(
                tooltip: 'Remove date',
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 16),
                color: AppColors.mutedForeground,
              ),
          ],
        ),
      ),
    ),
  );
}

/// The quiet line under the Days row (2a, 2b, 2c).
class CreatePlanDaysNote extends StatelessWidget {
  const CreatePlanDaysNote({
    super.key,
    required this.limits,
    required this.days,
    this.onSeePro,
  });

  final PlanLimits limits;
  final int days;
  final VoidCallback? onSeePro;

  @override
  Widget build(BuildContext context) {
    if (limits.pro) {
      return Text(
        'Up to ${limits.maxDays} days. You can add or remove days later.',
        style: AppTypeScale.meta,
      );
    }
    if (days < limits.maxDays) {
      return Text(
        'You can add more days later, up to ${limits.maxDays} on Free.',
        style: AppTypeScale.meta,
      );
    }
    return Row(
      children: [
        Text(
          '${limits.maxDays} of ${limits.maxDays} days on Free.',
          style: AppTypeScale.meta,
        ),
        if (onSeePro != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(44, 32),
              textStyle: AppTypeScale.meta.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: onSeePro,
            child: const Text('See Pro'),
          ),
      ],
    );
  }
}
