import 'package:flutter/material.dart';

import '../../../core/widgets/app_shimmer.dart';
import '../../../design/app_text_styles.dart';
import 'badges_hero_card.dart';

/// The Badges tab while the collection loads: the same layout with
/// shimmering placeholders (claimed card, dots, heading, badge grid), so
/// the real content drops in without the page jumping.
class BadgesLoading extends StatelessWidget {
  const BadgesLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading your badges',
      child: AppShimmer(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList.list(
                children: const [
                  SizedBox(
                    height: 32,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Collection',
                        style: AppTextStyles.headingForeground,
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  BadgesCardShell(
                    padding: EdgeInsets.fromLTRB(19, 18, 19, 17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AppSkeleton(width: 44, height: 52, radius: 8),
                            SizedBox(width: 8),
                            AppSkeleton(width: 150, height: 14),
                          ],
                        ),
                        SizedBox(height: 14),
                        AppSkeleton(height: 20, radius: 4),
                        SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppSkeleton(width: 90, height: 12),
                            AppSkeleton(width: 56, height: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14),
                  Center(child: AppSkeleton(width: 30, height: 6, radius: 3)),
                  SizedBox(height: 20),
                  AppSkeleton(width: 100, height: 12),
                  SizedBox(height: 8),
                  AppSkeleton(width: 120, height: 24),
                  SizedBox(height: 8),
                  AppSkeleton(width: 240, height: 12),
                  SizedBox(height: 16),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: 12,
                itemBuilder: (_, _) => const AppSkeleton(circle: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
