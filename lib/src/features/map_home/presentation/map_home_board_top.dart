import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../detection/application/detection_controller.dart';
import '../application/location_banner_visibility.dart';
import '../domain/map_home_models.dart';
import 'map_home_location_banner.dart';
import 'map_home_map_focus.dart';
import 'map_home_map_status.dart';
import 'map_home_stat_card.dart';

/// Home's top: the stat card (or, for a few seconds after launch while
/// detection can't work at full strength, the location banner in its place),
/// then the drawn map layer
/// (hidden once the real map is showing) with the offline-map chip over it.
class MapHomeBoardTop extends ConsumerWidget {
  const MapHomeBoardTop({
    super.key,
    required this.data,
    required this.headerKey,
    required this.fade,
    required this.isMapInteracting,
    this.focus,
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

  /// Clears the stat card while the real map is being worked.
  final MapHomeMapFocus? focus;
  final VoidCallback? onOpenProfile;
  final bool showRealMap;
  final Widget drawnMap;
  final bool showOfflineChip;
  final VoidCallback onRetryRealMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = data;
    final reason = ref.watch(
      detectionControllerProvider.select((s) => s.status.reason),
    );
    final bannerVisible = ref.watch(locationBannerVisibleProvider);
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
              child: MapHomeFocusFade(
                focus: focus,
                child: AnimatedSwitcher(
                  duration: fade,
                  child:
                      MapHomeLocationBanner.shows(
                        reason,
                        visible: bannerVisible,
                      )
                      ? MapHomeLocationBanner(
                          key: ValueKey('location-banner-${reason.name}'),
                          reason: reason,
                        )
                      : board == null
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
