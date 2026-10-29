import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../domain/plan_offline.dart';

/// Saves the map around a plan on the phone so it opens without signal.
/// Kept behind this small interface: everything Mapbox-specific lives in
/// [MapboxPlanOfflineMap].
abstract interface class PlanOfflineMap {
  /// Saves the style and the map tiles inside [bounds]. [onProgress] gets
  /// 0 to 1.
  Future<void> download(
    String regionId,
    PlanBounds bounds,
    void Function(double progress) onProgress,
  );

  Future<void> remove(String regionId);
}

class MapboxPlanOfflineMap implements PlanOfflineMap {
  const MapboxPlanOfflineMap();

  static const _style = MapboxStyles.OUTDOORS;
  static const _minZoom = 5;

  @override
  Future<void> download(
    String regionId,
    PlanBounds bounds,
    void Function(double progress) onProgress,
  ) async {
    final offline = await OfflineManager.create();
    final tiles = await TileStore.createDefault();

    // The style, its fonts and icons: the first tenth of the progress.
    await offline.loadStylePack(
      _style,
      StylePackLoadOptions(
        glyphsRasterizationMode:
            GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY,
        acceptExpired: false,
      ),
      (progress) {
        final total = progress.requiredResourceCount;
        if (total > 0) {
          onProgress(0.1 * progress.completedResourceCount / total);
        }
      },
    );

    // The map tiles inside the box.
    await tiles.loadTileRegion(
      regionId,
      TileRegionLoadOptions(
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [bounds.west, bounds.south],
              [bounds.east, bounds.south],
              [bounds.east, bounds.north],
              [bounds.west, bounds.north],
              [bounds.west, bounds.south],
            ],
          ],
        },
        descriptorsOptions: [
          TilesetDescriptorOptions(
            styleURI: _style,
            minZoom: _minZoom,
            maxZoom: bounds.maxZoom,
          ),
        ],
        acceptExpired: true,
        networkRestriction: NetworkRestriction.NONE,
      ),
      (progress) {
        final total = progress.requiredResourceCount;
        if (total > 0) {
          onProgress(0.1 + 0.9 * progress.completedResourceCount / total);
        }
      },
    );
  }

  @override
  Future<void> remove(String regionId) async {
    final tiles = await TileStore.createDefault();
    await tiles.removeRegion(regionId);
  }
}
