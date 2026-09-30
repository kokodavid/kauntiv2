import 'package:flutter/material.dart';

import '../../../core/widgets/app_shimmer.dart';
import '../../../design/app_colors.dart';

/// Past Trips while the list loads: shimmering cards shaped like
/// [JourneyCard] (the folder-stack depth, route preview with title and
/// facts, the started line and the Rename/Delete menu below), so the
/// real cards drop in without the list jumping.
class JourneyCardsLoading extends StatelessWidget {
  const JourneyCardsLoading({super.key, this.count = 2});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading your Trips',
      child: AppShimmer(
        child: Column(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              const _CardSkeleton(),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 22,
          right: 6,
          bottom: -6,
          child: _peek(AppColors.trackInactive),
        ),
        Positioned(
          left: 12,
          right: 2,
          bottom: -3,
          child: _peek(AppColors.lockedFill),
        ),
        _card(),
      ],
    );
  }

  static Widget _peek(Color color) => Container(
    height: 14,
    decoration: BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(18),
      ),
    ),
  );

  static Widget _card() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 208,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppSkeleton(radius: 20),
              Positioned(
                left: 12,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OnPhoto(width: 150, height: 16),
                    SizedBox(height: 6),
                    _OnPhoto(width: 96, height: 11),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: _OnPhoto(width: 92, height: 36, radius: 18),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                AppSkeleton(width: 140, height: 12),
                Spacer(),
                AppSkeleton(width: 22, height: 22, circle: true),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// A lighter bar where the title, facts and Replay sit on the preview.
class _OnPhoto extends StatelessWidget {
  const _OnPhoto({required this.width, required this.height, this.radius = 6});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
