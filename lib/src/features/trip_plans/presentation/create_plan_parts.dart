import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// An upper-case field label ("TITLE", "START FROM").
class CreatePlanLabel extends StatelessWidget {
  const CreatePlanLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(), style: AppTypeScale.sectionLabel),
  );
}

/// One start choice ("Current location", "Choose a place", "Pick on map").
class CreatePlanChip extends StatelessWidget {
  const CreatePlanChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? AppColors.accent : AppColors.exploreSurface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.exploreBorder,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected
                  ? AppColors.accentForeground
                  : AppColors.foreground,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The Days stepper (− n +). At the Free limit the + turns grey; tapping
/// it still reports [onBlockedIncrement] so the sheet can explain.
class CreatePlanDaysStepper extends StatelessWidget {
  const CreatePlanDaysStepper({
    super.key,
    required this.days,
    required this.max,
    required this.onChanged,
    required this.onBlockedIncrement,
  });

  final int days;
  final int max;
  final ValueChanged<int> onChanged;
  final VoidCallback onBlockedIncrement;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: AppColors.exploreSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.inputBorder),
    ),
    child: Row(
      children: [
        _StepButton(
          icon: Icons.remove,
          enabled: days > 1,
          label: 'One day fewer',
          onTap: () => onChanged(days - 1),
        ),
        Expanded(
          child: Text(
            '$days',
            textAlign: TextAlign.center,
            style: AppTypeScale.cardTitle,
          ),
        ),
        _StepButton(
          icon: Icons.add,
          enabled: days < max,
          label: 'One day more',
          onTap: days < max ? () => onChanged(days + 1) : onBlockedIncrement,
        ),
      ],
    ),
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.accent : AppColors.lockedStroke,
        ),
      ),
    ),
  );
}

/// An inline note in the sheet: the amber location warning (2c) or the
/// accent Free-limit callout (2d).
class CreatePlanNote extends StatelessWidget {
  const CreatePlanNote({
    super.key,
    required this.child,
    this.warning = false,
    this.trailing,
  });

  final Widget child;
  final bool warning;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: warning ? AppColors.warningBackground : AppColors.accentTint,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: warning ? AppColors.warningBorder : AppColors.infoBorder,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (warning)
          const Padding(
            padding: EdgeInsets.only(right: 8, top: 1),
            child: Icon(
              Icons.error_outline,
              size: 18,
              color: AppColors.warningIcon,
            ),
          ),
        Expanded(child: child),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    ),
  );
}
