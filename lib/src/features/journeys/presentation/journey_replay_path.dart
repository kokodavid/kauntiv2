import '../../../core/map/replay_map_types.dart';
import '../domain/journey_route.dart';

/// A [JourneyRoute] as the shared replay map sees it. It only wraps the
/// route, so asking for a new "played so far" path every frame stays cheap.
class JourneyReplayPath implements ReplayPath {
  const JourneyReplayPath(this.route);

  final JourneyRoute route;

  @override
  int get pointCount => route.pointCount;

  @override
  ReplayBounds? get bounds => route.bounds;

  @override
  MapLatLng? get lastPoint {
    final point = route.lastPoint;
    return point == null
        ? null
        : (latitude: point.latitude, longitude: point.longitude);
  }

  @override
  Map<String, Object?> toGeoJson() => route.toGeoJson();
}
