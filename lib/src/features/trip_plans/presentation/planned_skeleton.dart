import 'package:flutter/material.dart';

import '../../../core/widgets/app_shimmer.dart';
import '../../../design/app_colors.dart';

/// Planned on first load (design 1e): blocks the same size as the plan
/// cards, so nothing jumps when they arrive.
class PlannedSkeleton extends StatelessWidget {
  const PlannedSkeleton({super.key});

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeleton(height: 48, radius: 24),
        const SizedBox(height: 24),
        const AppSkeleton(width: 110, height: 20),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 98,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.exploreSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.exploreBorder),
            ),
            child: const Row(
              children: [
                AppSkeleton(width: 72, height: 72, radius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(width: 170, height: 14),
                      SizedBox(height: 8),
                      AppSkeleton(width: 110, height: 10),
                      SizedBox(height: 8),
                      AppSkeleton(width: 150, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    ),
  );
}
