import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// The full-width "+ Plan a trip" pill at the top of Planned (design 1b).
class PlanTripButton extends StatelessWidget {
  const PlanTripButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentForeground,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Plan a trip'),
    ),
  );
}
