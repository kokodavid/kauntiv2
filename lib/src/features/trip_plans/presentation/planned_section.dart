import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// A Planned section heading ("Upcoming", "Shared with you", "Past") with
/// an optional quiet line under it and an optional action on the right.
class PlannedSectionHeader extends StatelessWidget {
  const PlannedSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypeScale.sectionTitle),
              if (subtitle != null) Text(subtitle!, style: AppTypeScale.meta),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              minimumSize: const Size(44, 44),
              textStyle: AppTypeScale.action,
            ),
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    ),
  );
}
