import 'package:flutter/material.dart';

import '../../../core/domain/map_place.dart';
import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';
import 'map_home_links.dart';
import 'map_home_map_focus.dart';
import 'map_home_map_status.dart';
import 'real_map_view.dart';

/// The real (Mapbox) map running edge to edge behind Home's header, with the
/// scrim under the header and the opaque page background that covers it
/// until the map's style is up or whenever it isn't the map being shown.
class MapHomeRealMapLayer extends StatelessWidget {
  const MapHomeRealMapLayer({
    super.key,
    required this.focus,
    required this.mapKey,
    required this.accessToken,
    required this.data,
    required this.topInset,
    required this.showRealMap,
    required this.fade,
    required this.onReady,
    required this.onFailed,
    this.loadPlaces,
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
    this.onPlaceRoute,
  });

  final MapHomeMapFocus focus;
  final Key mapKey;
  final String accessToken;
  final MapHomeBoardData data;
  final double topInset;
  final bool showRealMap;
  final Duration fade;
  final VoidCallback onReady;
  final VoidCallback onFailed;
  final Future<List<MapPlace>> Function()? loadPlaces;
  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;
  final OpenDirections? onRoute;
  final OpenPlaceDirections? onPlaceRoute;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MapHomeMapTouchSensor(
          focus: focus,
          child: RealMapView(
            key: mapKey,
            accessToken: accessToken,
            badges: data.countyBadges,
            homeCountySlug: data.homeCounty?.slug,
            loadPlaces: loadPlaces,
            topInset: topInset,
            onReady: onReady,
            onFailed: onFailed,
            onOpenCounty: onOpenCounty,
            onOpenPlace: onOpenPlace,
            onRoute: onRoute,
            onPlaceRoute: onPlaceRoute,
          ),
        ),
        const MapHomeHeaderScrim(),
        // Opaque page background behind everything until the real map's
        // style is up (so its blank canvas never flashes) or whenever
        // it's not the map being shown at all, covering the header area
        // too, which the drawn map's own layer can't reach.
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: showRealMap ? 0 : 1,
            duration: fade,
            child: const ColoredBox(color: AppColors.pageBackground),
          ),
        ),
      ],
    );
  }
}
