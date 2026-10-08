import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/trip_route.dart';

/// Driving routes from the Mapbox Directions API.
class MapboxDirectionsClient {
  MapboxDirectionsClient({required this.accessToken, http.Client? client})
    : _client = client ?? http.Client();

  final String accessToken;
  final http.Client _client;

  void close() => _client.close();

  Future<TripRoute> drive({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    List<TripRoutePoint> via = const [],
  }) async {
    final stops = [for (final p in via) '${p.lng},${p.lat}'];
    final path = ['$fromLng,$fromLat', ...stops, '$toLng,$toLat'].join(';');
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
      throw const TripRouteException("Couldn't reach the route service.");
    }
    if (response.statusCode != 200) {
      throw const TripRouteException("Couldn't plan a route right now.");
    }
    return parse(response.body);
  }

  static TripRoute parse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, Object?>;
      final routes = json['routes'] as List<Object?>;
      if (routes.isEmpty) {
        throw const TripRouteException('No road route found to this place.');
      }
      final route = routes.first! as Map<String, Object?>;
      final coordinates =
          (route['geometry']! as Map<String, Object?>)['coordinates']!
              as List<Object?>;
      return TripRoute(
        points: [
          for (final c in coordinates)
            TripRoutePoint(
              ((c! as List<Object?>)[1]! as num).toDouble(),
              ((c as List<Object?>)[0]! as num).toDouble(),
            ),
        ],
        distanceMeters: (route['distance']! as num).toDouble(),
        durationSeconds: (route['duration']! as num).toDouble(),
      );
    } on TripRouteException {
      rethrow;
    } on Object {
      throw const TripRouteException("Couldn't read the planned route.");
    }
  }
}
