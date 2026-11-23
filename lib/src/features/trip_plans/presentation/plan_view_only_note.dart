import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// Shown to a view-only member: they can look, not change.
class PlanViewOnlyNote extends StatelessWidget {
  const PlanViewOnlyNote({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.noteBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.exploreBorder),
    ),
    child: const Row(
      children: [
        Icon(Icons.visibility_outlined, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'You can see this plan but not change it.',
            style: AppTypeScale.small,
          ),
        ),
      ],
    ),
  );
}
