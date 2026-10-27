import 'package:flutter/material.dart';

import '../../../core/widgets/app_shimmer.dart';

/// The Passport while it loads or the account is restored: shapes only, no
/// names, art or counts, so nothing flashes and then changes.
class PassportSkeleton extends StatelessWidget {
  const PassportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading your passport',
      child: AppShimmer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
          children: [
            const AppSkeleton(width: 220, height: 30),
            const SizedBox(height: 14),
            const AppSkeleton(height: 120, radius: 20),
            const SizedBox(height: 14),
            const AppSkeleton(height: 84, radius: 20),
            const SizedBox(height: 14),
            const AppSkeleton(height: 44, radius: 14),
            const SizedBox(height: 20),
            for (var row = 0; row < 2; row++) ...[
              Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    const Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: AppSkeleton(circle: true),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
