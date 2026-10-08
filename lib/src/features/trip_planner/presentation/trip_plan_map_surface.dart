import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';

/// Keeps an intentional loading state above the native map until its style
/// and route layers are ready, avoiding a white platform-view flash.
class TripPlanMapSurface extends StatelessWidget {
  const TripPlanMapSurface({
    super.key,
    required this.map,
    required this.loading,
    required this.rounded,
    required this.borderRadius,
    required this.height,
  });

  final Widget map;
  final bool loading;
  final bool rounded;
  final BorderRadius borderRadius;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final surface = Stack(
      fit: StackFit.expand,
      children: [
        map,
        if (loading)
          const ColoredBox(
            color: AppColors.lockedFill,
            child: Center(
              child: AppProgressIndicator(color: AppColors.accent, radius: 12),
            ),
          ),
      ],
    );
    if (!rounded) return surface;
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: double.infinity, height: height, child: surface),
    );
  }
}

/// A deliberate recovery state for a Mapbox view that could not load.
class TripPlanMapFailure extends StatelessWidget {
  const TripPlanMapFailure({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.lockedFill,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 28),
            const SizedBox(height: 10),
            const Text('Couldn\'t load the map', style: AppTypeScale.itemTitle),
            const SizedBox(height: 6),
            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTypeScale.small,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    ),
  );
}

class TripPlanMapUnavailable extends StatelessWidget {
  const TripPlanMapUnavailable({
    super.key,
    required this.borderRadius,
    required this.height,
  });

  final BorderRadius borderRadius;
  final double? height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius,
    child: SizedBox(
      height: height,
      child: const ColoredBox(
        color: AppColors.lockedFill,
        child: Center(
          child: Text(
            'Map unavailable in this build',
            style: AppTypeScale.small,
          ),
        ),
      ),
    ),
  );
}
