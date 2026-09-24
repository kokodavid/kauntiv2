import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import 'explore_header.dart';
import 'explore_styles.dart';

/// Explore's first frame while the board loads (v1
/// `_DiscoverResolvingState`): the real title over neutral skeleton
/// blocks, so no zero counts or stale account content can flash. With
/// [onRetry] set it shows the load error card instead of the list block.
class ExploreResolvingState extends StatelessWidget {
  const ExploreResolvingState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return ListView(
      key: const Key('explore-resolving-state'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
      children: [
        const ExploreTopBar(),
        const SizedBox(height: 12),
        const _Block(height: 36, radius: 30),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(flex: 22, child: _Block(height: 34, radius: 20)),
            SizedBox(width: 8),
            Expanded(flex: 45, child: _Block(height: 34, radius: 20)),
            SizedBox(width: 8),
            Expanded(flex: 27, child: _Block(height: 34, radius: 20)),
          ],
        ),
        const SizedBox(height: 10),
        if (retry == null)
          const _Block(height: 268, radius: 16)
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: ExploreStyles.cardDecoration,
            child: Column(
              children: [
                Text(
                  "Couldn't load Discover.",
                  style: AppTextStyles.headingForeground.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Check your connection and try again.',
                  style: ExploreStyles.emptyBody,
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: retry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.exploreBorder,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
