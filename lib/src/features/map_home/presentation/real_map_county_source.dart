import 'package:flutter/services.dart';

import '../application/county_camera_fit.dart';
import '../application/county_geojson_builder.dart';
import '../domain/map_home_models.dart';

/// Loads the bundled county boundaries once for a real map: the GeoJSON
/// (tagged with badge states) for the county layers, and each county's
/// bounding box for camera flights.
class RealMapCountySource {
  RealMapCountySource({required this.badges, required this.homeCountySlug});

  static const _asset = 'assets/geo/kenya_counties.geojson';

  final List<MapHomeCountyBadge> badges;
  final String? homeCountySlug;

  Future<String>? _geoJson;
  Map<int, CountyBounds> _bounds = const {};

  Future<String> geoJson() => _geoJson ??= _load();

  CountyBounds? boundsFor(int? code) => _bounds[code];

  Future<String> _load() async {
    final raw = await rootBundle.loadString(_asset);
    _bounds = CountyCameraFit.boundsByCode(raw);
    return CountyGeoJsonBuilder.withBadgeStates(
      boundariesGeoJson: raw,
      badges: badges,
      homeCountySlug: homeCountySlug,
    );
  }
}
