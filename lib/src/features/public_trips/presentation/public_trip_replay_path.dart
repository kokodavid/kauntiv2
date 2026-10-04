import '../../../core/map/replay_map_types.dart';
import '../domain/public_trip_track.dart';

/// Public route lines as the shared replay map sees them.
class PublicTripReplayPath implements ReplayPath {
  PublicTripReplayPath(this.lines)
    : pointCount = lines.fold(0, (sum, line) => sum + line.length);

  final List<List<PublicTripLatLng>> lines;

  @override
  final int pointCount;

  @override
  ReplayBounds? get bounds {
    if (pointCount == 0) return null;
    var south = 90.0, north = -90.0, west = 180.0, east = -180.0;
    for (final line in lines) {
      for (final p in line) {
        if (p.latitude < south) south = p.latitude;
        if (p.latitude > north) north = p.latitude;
        if (p.longitude < west) west = p.longitude;
        if (p.longitude > east) east = p.longitude;
      }
    }
    return (south: south, west: west, north: north, east: east);
  }

  @override
  MapLatLng? get lastPoint {
    for (final line in lines.reversed) {
      if (line.isNotEmpty) return line.last;
    }
    return null;
  }

  @override
  Map<String, Object?> toGeoJson() => {
    'type': 'FeatureCollection',
    'features': [
      for (final line in lines)
        if (line.isNotEmpty)
          {
            'type': 'Feature',
            'properties': <String, Object?>{},
            'geometry': line.length == 1
                ? {
                    'type': 'Point',
                    'coordinates': [
                      line.single.longitude,
                      line.single.latitude,
                    ],
                  }
                : {
                    'type': 'LineString',
                    'coordinates': [
                      for (final p in line) [p.longitude, p.latitude],
                    ],
                  },
          },
    ],
  };
}
