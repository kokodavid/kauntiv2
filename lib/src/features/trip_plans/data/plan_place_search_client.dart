import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/plan_place_suggestion.dart';

/// Searches real-world places by what the user has typed so far.
abstract interface class PlanPlaceSearchClient {
  /// Suggestions for [query], nearest to ([nearLat], [nearLng]) first when
  /// those are known. Throws [PlanPlaceSearchFailure] when it can't search.
  Future<List<PlanPlaceSuggestion>> search(
    String query, {
    double? nearLat,
    double? nearLng,
  });
}

class PlanPlaceSearchFailure implements Exception {
  const PlanPlaceSearchFailure(this.message);

  final String message;
}

/// Mapbox Geocoding v6, limited to Kenya. The result is kept in the plan, so
/// requests ask for `permanent` results (Mapbox only lets stored results be
/// kept that way; the account needs a card on file).
class MapboxPlanPlaceSearch implements PlanPlaceSearchClient {
  MapboxPlanPlaceSearch({
    required this.accessToken,
    http.Client? client,
    this.permanent = true,
  }) : _client = client ?? http.Client();

  final String accessToken;
  final bool permanent;
  final http.Client _client;

  @override
  Future<List<PlanPlaceSuggestion>> search(
    String query, {
    double? nearLat,
    double? nearLng,
  }) async {
    final uri = Uri.https('api.mapbox.com', '/search/geocode/v6/forward', {
      'q': query,
      'country': 'ke',
      'language': 'en',
      'limit': '10',
      'autocomplete': 'true',
      'permanent': '$permanent',
      if (nearLat != null && nearLng != null) 'proximity': '$nearLng,$nearLat',
      'access_token': accessToken,
    });
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 8));
    } on Object {
      throw const PlanPlaceSearchFailure("Couldn't reach the search service.");
    }
    if (response.statusCode != 200) {
      throw const PlanPlaceSearchFailure("Couldn't search right now.");
    }
    return parse(response.body);
  }

  static List<PlanPlaceSuggestion> parse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, Object?>;
      final features = (json['features'] as List<Object?>?) ?? const [];
      final out = <PlanPlaceSuggestion>[];
      for (final feature in features) {
        final map = feature! as Map<String, Object?>;
        final coordinates =
            (map['geometry']! as Map<String, Object?>)['coordinates']!
                as List<Object?>;
        final props = map['properties']! as Map<String, Object?>;
        final name = (props['name_preferred'] ?? props['name']) as String?;
        if (name == null || name.trim().isEmpty) continue;
        final address = props['place_formatted'] as String?;
        out.add(
          PlanPlaceSuggestion(
            name: name.trim(),
            address: address?.trim(),
            lat: (coordinates[1]! as num).toDouble(),
            lng: (coordinates[0]! as num).toDouble(),
          ),
        );
      }
      return out;
    } on Object {
      throw const PlanPlaceSearchFailure("Couldn't read the search results.");
    }
  }
}
