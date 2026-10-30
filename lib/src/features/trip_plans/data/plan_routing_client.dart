import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/plan_route.dart';

/// Works out the road for one day.
abstract interface class PlanRoutingClient {
  Future<PlanRoute> drive(List<PlanRoutePoint> points);
}

/// Driving routes from the Mapbox Directions API (up to 25 points a call;
/// a Pro day has at most 22).
class MapboxPlanRoutingClient implements PlanRoutingClient {
  MapboxPlanRoutingClient({required this.accessToken, http.Client? client})
    : _client = client ?? http.Client();

  final String accessToken;
  final http.Client _client;

  @override
  Future<PlanRoute> drive(List<PlanRoutePoint> points) async {
    if (points.length < 2 || points.length > 25) {
      throw const PlanRouteFailure('This day has no road to plan.');
    }
    final path = points.map((p) => '${p.lng},${p.lat}').join(';');
    final uri = Uri.https(
      'api.mapbox.com',
      '/directions/v5/mapbox/driving/$path',
      {
        'geometries': 'geojson',
        'overview': 'full',
        'access_token': accessToken,
      },
    );
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 12));
    } on Object {
      throw const PlanRouteFailure("Couldn't reach the route service.");
    }
    if (response.statusCode != 200) {
      throw const PlanRouteFailure("Couldn't plan the road right now.");
    }
    return parse(response.body);
  }

  static PlanRoute parse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, Object?>;
      final routes = json['routes'] as List<Object?>;
      if (routes.isEmpty) {
        throw const PlanRouteFailure('No road found between these places.');
      }
      final route = routes.first! as Map<String, Object?>;
      final coordinates =
          (route['geometry']! as Map<String, Object?>)['coordinates']!
              as List<Object?>;
      return PlanRoute(
        points: [
          for (final c in coordinates)
            PlanRoutePoint(
              ((c! as List<Object?>)[1]! as num).toDouble(),
              ((c as List<Object?>)[0]! as num).toDouble(),
            ),
        ],
        distanceM: (route['distance']! as num).round(),
        durationS: (route['duration']! as num).round(),
        legs: [
          for (final leg in (route['legs'] as List<Object?>? ?? const []))
            PlanLeg(
              distanceM: ((leg! as Map<String, Object?>)['distance']! as num)
                  .round(),
              durationS: ((leg as Map<String, Object?>)['duration']! as num)
                  .round(),
            ),
        ],
      );
    } on PlanRouteFailure {
      rethrow;
    } on Object {
      throw const PlanRouteFailure("Couldn't read the planned road.");
    }
  }
}
