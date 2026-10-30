import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/plan_place_suggestion.dart';
import 'plan_place_search_client.dart';

/// Geoapify address and place autocomplete (OpenStreetMap data), limited to
/// Kenya. Unlike an address-only search it also finds businesses and
/// landmarks (petrol stations, malls, hotels, schools).
class GeoapifyPlanPlaceSearch implements PlanPlaceSearchClient {
  GeoapifyPlanPlaceSearch({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  @override
  Future<List<PlanPlaceSuggestion>> search(
    String query, {
    double? nearLat,
    double? nearLng,
  }) async {
    final uri = Uri.https('api.geoapify.com', '/v1/geocode/autocomplete', {
      'text': query,
      'filter': 'countrycode:ke',
      'lang': 'en',
      'limit': '10',
      'format': 'json',
      if (nearLat != null && nearLng != null)
        'bias': 'proximity:$nearLng,$nearLat',
      'apiKey': apiKey,
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

  /// Reads the `format=json` answer: a `results` list, each with `lat`, `lon`,
  /// a first line (`address_line1`, the name) and a second (`address_line2`).
  static List<PlanPlaceSuggestion> parse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, Object?>;
      final results = (json['results'] as List<Object?>?) ?? const [];
      final out = <PlanPlaceSuggestion>[];
      for (final result in results) {
        final map = result! as Map<String, Object?>;
        final lat = map['lat'];
        final lon = map['lon'];
        if (lat is! num || lon is! num) continue;
        final name = _text(map['address_line1']) ?? _text(map['name']);
        if (name == null) continue;
        out.add(
          PlanPlaceSuggestion(
            name: name,
            address: _text(map['address_line2']),
            lat: lat.toDouble(),
            lng: lon.toDouble(),
          ),
        );
      }
      return out;
    } on Object {
      throw const PlanPlaceSearchFailure("Couldn't read the search results.");
    }
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
