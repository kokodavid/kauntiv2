import 'package:flutter/material.dart';

import '../domain/map_home_models.dart';
import 'map_home_detection_paused_chip.dart';
import 'map_home_map_status.dart';
import 'map_home_stat_card.dart';

/// Home's top: the stat card, then the drawn map layer (hidden once the real
/// map is showing) with the detection-paused and offline-map chips over it.
class MapHomeBoardTop extends StatelessWidget {
  const MapHomeBoardTop({
    super.key,
    required this.data,
    required this.headerKey,
    required this.fade,
    required this.isMapInteracting,
    required this.onOpenProfile,
    required this.showRealMap,
    required this.drawnMap,
    required this.showOfflineChip,
    required this.onRetryRealMap,
  });

  final MapHomeBoardData? data;
  final Key headerKey;
  final Duration fade;
  final bool isMapInteracting;
  final VoidCallback? onOpenProfile;
  final bool showRealMap;
  final Widget drawnMap;
  final bool showOfflineChip;
  final VoidCallback onRetryRealMap;

  @override
  Widget build(BuildContext context) {
    final board = data;
    return Positioned.fill(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equal top and side margin around the card, so it sits a
            // little inset from the screen edges on every side.
            const SizedBox(height: 12),
            Padding(
              key: headerKey,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedSwitcher(
                duration: fade,
                child: board == null
                    ? MapHomeStatCard.loading(onOpenProfile: onOpenProfile)
                    : MapHomeStatCard(
                        key: const ValueKey('stat-card'),
                        exploredCount: board.exploredCount,
                        totalCounties: board.totalCounties,
                        compact: isMapInteracting,
                        tier: board.tier,
                        onOpenProfile: onOpenProfile,
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: showRealMap,
                      child: AnimatedOpacity(
                        opacity: showRealMap ? 0 : 1,
                        duration: fade,
                        child: AnimatedSwitcher(
                          duration: fade,
                          child: drawnMap,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MapHomeDetectionPausedChip(),
                        if (showOfflineChip) ...[
                          const SizedBox(height: 6),
                          MapHomeOfflineMapChip(onRetry: onRetryRealMap),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
