/// A position on the map.
typedef MapLatLng = ({double latitude, double longitude});

/// A route's south-west and north-east corners.
typedef ReplayBounds = ({double south, double west, double north, double east});

/// A key moment pin: a photo or a note, tied to the route point it belongs
/// to so the map can colour it pending or passed against the playhead.
enum ReplayMomentKind { photo, note }

typedef ReplayMapMoment = ({MapLatLng at, ReplayMomentKind kind, int index});

/// What the replay map needs to know about a route, whatever feature it
/// came from. Cheap to create: it wraps the feature's own route rather than
/// copying it, because replay asks for a new "played so far" path often.
abstract interface class ReplayPath {
  int get pointCount;

  /// Null for an empty path.
  ReplayBounds? get bounds;

  /// The newest point; null for an empty path.
  MapLatLng? get lastPoint;

  /// One LineString per run of 2+ points and a Point for a lone point, in a
  /// FeatureCollection.
  Map<String, Object?> toGeoJson();
}
