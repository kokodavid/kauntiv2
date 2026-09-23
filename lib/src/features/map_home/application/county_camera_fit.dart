import 'dart:convert';
import 'dart:math' as math;

/// A county's bounding box in degrees.
typedef CountyBounds = ({
  double minLng,
  double minLat,
  double maxLng,
  double maxLat,
});

/// Camera maths for flying the real map to a county: bounding boxes from
/// the bundled boundaries GeoJSON, and a zoom that fits a box into the
/// visible part of the screen.
abstract final class CountyCameraFit {
  /// Bounding box per county code, from `kenya_counties.geojson`.
  static Map<int, CountyBounds> boundsByCode(String boundariesGeoJson) {
    final collection = jsonDecode(boundariesGeoJson) as Map<String, Object?>;
    final features = (collection['features']! as List<Object?>)
        .cast<Map<String, Object?>>();
    return {
      for (final feature in features)
        (feature['properties']! as Map<String, Object?>)['code']! as int:
            _bounds(feature['geometry']! as Map<String, Object?>),
    };
  }

  static CountyBounds _bounds(Map<String, Object?> geometry) {
    var minLng = double.infinity, minLat = double.infinity;
    var maxLng = -double.infinity, maxLat = -double.infinity;
    for (final polygon in geometry['coordinates']! as List<Object?>) {
      for (final ring in polygon! as List<Object?>) {
        for (final point in ring! as List<Object?>) {
          final pair = point! as List<Object?>;
          final lng = (pair[0]! as num).toDouble();
          final lat = (pair[1]! as num).toDouble();
          minLng = math.min(minLng, lng);
          maxLng = math.max(maxLng, lng);
          minLat = math.min(minLat, lat);
          maxLat = math.max(maxLat, lat);
        }
      }
    }
    return (minLng: minLng, minLat: minLat, maxLng: maxLng, maxLat: maxLat);
  }

  /// Web-Mercator zoom that fits [bounds] into a [width] x [height]
  /// logical-pixel area with [fill] of it used, clamped to [minZoom] to
  /// [maxZoom]. Kenya straddles the equator, so latitude is treated like
  /// longitude (error under 1% there).
  static double zoomToFit(
    CountyBounds bounds, {
    required double width,
    required double height,
    double fill = 0.8,
    double minZoom = 5.5,
    double maxZoom = 11,
  }) {
    const tileSize = 512.0;
    final spanLng = math.max(bounds.maxLng - bounds.minLng, 0.01);
    final spanLat = math.max(bounds.maxLat - bounds.minLat, 0.01);
    double zoomFor(double pixels, double span) =>
        math.log(360 * pixels * fill / (tileSize * span)) / math.ln2;
    final zoom = math.min(zoomFor(width, spanLng), zoomFor(height, spanLat));
    return zoom.clamp(minZoom, maxZoom);
  }

  static ({double lng, double lat}) centerOf(CountyBounds bounds) => (
    lng: (bounds.minLng + bounds.maxLng) / 2,
    lat: (bounds.minLat + bounds.maxLat) / 2,
  );
}
