import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_failure.dart';

Widget _block(double height, {double? width}) => Container(
  height: height,
  width: width,
  decoration: BoxDecoration(
    color: AppColors.lockedFill,
    borderRadius: BorderRadius.circular(14),
  ),
);

/// Shapes where the plan will be while it loads (no spinner flash).
class PlanScreenSkeleton extends StatelessWidget {
  const PlanScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _block(22, width: 200),
        const SizedBox(height: 8),
        _block(14, width: 140),
        const SizedBox(height: 16),
        _block(240),
        const SizedBox(height: 12),
        _block(72),
        const SizedBox(height: 12),
        _block(120),
      ],
    ),
  );
}

/// The plan couldn't be shown: gone or no longer yours, or a plain failure.
class PlanScreenProblem extends StatelessWidget {
  const PlanScreenProblem({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onBack,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  bool get _gone =>
      error is PlanFailure &&
      (error as PlanFailure).kind == PlanFailureKind.notFound;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 32),
          const SizedBox(height: 12),
          Text(
            _gone ? 'This plan is no longer here' : "Couldn't open this plan",
            textAlign: TextAlign.center,
            style: AppTypeScale.cardTitle,
          ),
          const SizedBox(height: 6),
          Text(
            _gone
                ? 'It was deleted, or you were removed from it.'
                : 'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: AppTypeScale.small,
          ),
          const SizedBox(height: 16),
          if (!_gone)
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            onPressed: onBack,
            child: const Text('Back to trips'),
          ),
        ],
      ),
    ),
  );
}

/// A quiet block where the map would be: nothing to draw yet, or it
/// couldn't load.
class PlanMapNote extends StatelessWidget {
  const PlanMapNote({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.lockedFill,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: AppColors.mutedForeground),
            const SizedBox(height: 8),
            Text(title, style: AppTypeScale.itemTitle),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypeScale.small,
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}
