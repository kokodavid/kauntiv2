import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/feedback_models.dart';

/// "What is this about?": five pills, one picked.
class FeedbackCategoryPicker extends StatelessWidget {
  const FeedbackCategoryPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final FeedbackCategory selected;
  final ValueChanged<FeedbackCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in FeedbackCategory.values)
          _Pill(
            label: category.label,
            selected: category == selected,
            onTap: () => onChanged(category),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.chipLabel.copyWith(
              color: selected ? AppColors.accentForeground : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// "How bad is it?": three rows, one picked, each with what it means.
class FeedbackSeverityPicker extends StatelessWidget {
  const FeedbackSeverityPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final FeedbackSeverity? selected;
  final ValueChanged<FeedbackSeverity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final severity in FeedbackSeverity.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SeverityRow(
              severity: severity,
              selected: severity == selected,
              onTap: () => onChanged(severity),
            ),
          ),
      ],
    );
  }
}

class _SeverityRow extends StatelessWidget {
  const _SeverityRow({
    required this.severity,
    required this.selected,
    required this.onTap,
  });

  final FeedbackSeverity severity;
  final bool selected;
  final VoidCallback onTap;

  static Color _dot(FeedbackSeverity severity) => switch (severity) {
    FeedbackSeverity.blocking => AppColors.danger,
    FeedbackSeverity.major => AppColors.pendingFill,
    FeedbackSeverity.minor => AppColors.mutedForeground,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${severity.label}. ${severity.hint}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF4FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _dot(severity),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      severity.label,
                      style: AppTextStyles.listItemTitle.copyWith(fontSize: 14),
                    ),
                    Text(
                      severity.hint,
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppColors.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
