import 'package:flutter/material.dart';

import '../../../core/widgets/app_shimmer.dart';

/// The cards of a county page while its figures load: shapes only, so
/// nothing flashes in at zero and then changes.
class PassportCountyCardsSkeleton extends StatelessWidget {
  const PassportCountyCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading county details',
      child: const AppShimmer(
        child: Column(
          children: [
            AppSkeleton(height: 168, radius: 20),
            SizedBox(height: 14),
            AppSkeleton(height: 76, radius: 20),
            SizedBox(height: 14),
            AppSkeleton(height: 60, radius: 20),
          ],
        ),
      ),
    );
  }
}

/// A whole county page before the book itself has loaded: medallion, name,
/// the five steps and the cards.
class PassportCountyPageSkeleton extends StatelessWidget {
  const PassportCountyPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading county',
      child: AppShimmer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          children: [
            const Center(
              child: AppSkeleton(width: 104, height: 104, circle: true),
            ),
            const SizedBox(height: 16),
            const Center(child: AppSkeleton(width: 130, height: 21)),
            const SizedBox(height: 10),
            const Center(child: AppSkeleton(width: 120, height: 16)),
            const SizedBox(height: 22),
            Row(
              children: [
                for (var i = 0; i < 5; i++)
                  const Expanded(
                    child: Center(
                      child: AppSkeleton(width: 26, height: 26, circle: true),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const AppSkeleton(height: 168, radius: 20),
            const SizedBox(height: 14),
            const AppSkeleton(height: 76, radius: 20),
          ],
        ),
      ),
    );
  }
}
