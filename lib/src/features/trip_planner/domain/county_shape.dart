import 'trip_route.dart';

/// One polygon of a county: an outer ring and any holes (enclaves).
class CountyPolygon {
  CountyPolygon({required this.outer, this.holes = const []}) {
    var minLat = double.infinity;
    var maxLat = -double.infinity;
    var minLng = double.infinity;
    var maxLng = -double.infinity;
    for (final p in outer) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }
    _minLat = minLat;
    _maxLat = maxLat;
    _minLng = minLng;
    _maxLng = maxLng;
  }

  final List<TripRoutePoint> outer;
  final List<List<TripRoutePoint>> holes;
  late final double _minLat;
  late final double _maxLat;
  late final double _minLng;
  late final double _maxLng;

  bool contains(double lat, double lng) {
    if (lat < _minLat || lat > _maxLat || lng < _minLng || lng > _maxLng) {
      return false;
    }
    if (!_inRing(outer, lat, lng)) return false;
    for (final hole in holes) {
      if (_inRing(hole, lat, lng)) return false;
    }
    return true;
  }

  /// Ray casting: a point is inside when a ray from it crosses the ring an
  /// odd number of times.
  static bool _inRing(List<TripRoutePoint> ring, double lat, double lng) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i];
      final b = ring[j];
      if ((a.lat > lat) != (b.lat > lat) &&
          lng < (b.lng - a.lng) * (lat - a.lat) / (b.lat - a.lat) + a.lng) {
        inside = !inside;
      }
    }
    return inside;
  }
}

/// A county's boundary, by county code.
class CountyShape {
  const CountyShape({required this.code, required this.polygons});

  final int code;
  final List<CountyPolygon> polygons;

  bool contains(double lat, double lng) =>
      polygons.any((polygon) => polygon.contains(lat, lng));
}
