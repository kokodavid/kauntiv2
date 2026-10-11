import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'explore_header.dart';

/// Explore's first frame while the board loads (v1
/// `_DiscoverResolvingState`): the real title over neutral skeleton
/// blocks, so no zero counts or stale account content can flash.
class ExploreResolvingState extends StatelessWidget {
  const ExploreResolvingState({super.key});

  @override
  Widget build(BuildContext context) {
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
        const _Block(height: 268, radius: 16),
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
