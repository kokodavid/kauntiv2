/// A position on the map.
typedef JourneyLatLng = ({double latitude, double longitude});

/// A pin on the route: `start`, `end`, or a free-form `kind` string for
/// anything whose GeoJSON `properties.kind` a style layer matches on.
typedef JourneyMapPin = ({String kind, JourneyLatLng at});

/// A key moment pin and the route point it belongs to.
enum JourneyMapMomentKind { photo, note }

typedef JourneyMapMoment = ({
  JourneyLatLng at,
  JourneyMapMomentKind kind,
  int index,
});
