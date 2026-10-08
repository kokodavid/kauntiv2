import 'dart:math' as math;

import 'county_shape.dart';
import 'trip_route.dart';

/// Which counties a planned route passes through. A preview from the
/// route's line only: badges come from where a Trip actually goes, so this
/// is worded "passes through", never "you will earn".
abstract final class CountyCrossings {
  /// The route is checked at least this often (metres), so a long straight
  /// stretch between two points cannot skip a county.
  static const sampleMeters = 1000.0;

  /// County codes in the order the route first enters them.
  static List<int> along(
    List<TripRoutePoint> points,
    List<CountyShape> shapes,
  ) {
    final found = <int>[];
    CountyShape? current;
    void visit(double lat, double lng) {
      if (current != null && current!.contains(lat, lng)) return;
      for (final shape in shapes) {
        if (shape.contains(lat, lng)) {
          current = shape;
          if (!found.contains(shape.code)) found.add(shape.code);
          return;
        }
      }
      // Outside every boundary (a coarse edge, a lake): keep the last one.
    }

    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      visit(a.lat, a.lng);
      if (i + 1 == points.length) break;
      final b = points[i + 1];
      final steps = (_metres(a, b) / sampleMeters).floor();
      for (var s = 1; s <= steps; s++) {
        final t = s / (steps + 1);
        visit(a.lat + (b.lat - a.lat) * t, a.lng + (b.lng - a.lng) * t);
      }
    }
    return found;
  }

  /// Flat-earth distance: good to well under 1% over a stretch of road.
  static double _metres(TripRoutePoint a, TripRoutePoint b) {
    const perDegree = 111320.0;
    final dLat = (b.lat - a.lat) * perDegree;
    final dLng =
        (b.lng - a.lng) * perDegree * math.cos((a.lat + b.lat) * math.pi / 360);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }
}
