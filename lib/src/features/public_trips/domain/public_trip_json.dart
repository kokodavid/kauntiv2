import 'public_trip_moment_kind.dart';
import 'public_trip_owner_view.dart';

/// Parsing shared by what an owner previews and what a viewer opens: the
/// server uses one projection for both.

/// GeoJSON MultiLineString: lines of [longitude, latitude].
List<List<PublicTripPoint>> publicTripRouteLines(Object? route) {
  final coordinates = (route as Map<String, dynamic>?)?['coordinates'];
  if (coordinates is! List<dynamic>) return const [];
  return [
    for (final line in coordinates)
      [
        for (final point in line as List<dynamic>)
          PublicTripPoint(
            ((point as List<dynamic>)[1] as num).toDouble(),
            (point[0] as num).toDouble(),
          ),
      ],
  ];
}

List<PublicTripCounty> publicTripCounties(Object? counties) => [
  for (final raw in counties as List<dynamic>? ?? const [])
    PublicTripCounty(
      code: ((raw as Map<String, dynamic>)['code'] as num).toInt(),
      name: raw['name'] as String? ?? '',
    ),
];

/// Moments of a kind this app does not know are skipped, so a newer server
/// never breaks an older app.
List<PublicTripMoment> publicTripMoments(Object? moments) {
  final result = <PublicTripMoment>[];
  for (final raw in moments as List<dynamic>? ?? const []) {
    final item = raw as Map<String, dynamic>;
    final kind = PublicTripMomentKind.fromWire(item['kind'] as String?);
    if (kind == null) continue;
    result.add(
      PublicTripMoment(
        kind: kind,
        latitude: (item['latitude'] as num).toDouble(),
        longitude: (item['longitude'] as num).toDouble(),
      ),
    );
  }
  return result;
}
