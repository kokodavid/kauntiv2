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
