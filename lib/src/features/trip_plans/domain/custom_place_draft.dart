import 'plan_place_suggestion.dart';

/// A place from outside the Kaunti47 list, before it is saved to a plan:
/// a name and a point, searched for or dropped on the map.
class CustomPlaceDraft {
  const CustomPlaceDraft({
    required this.name,
    required this.lat,
    required this.lng,
    required this.source,
    this.address,
    this.countyCode,
  });

  /// A search result. [countyCode] is the county at its point, if any.
  factory CustomPlaceDraft.fromSuggestion(
    PlanPlaceSuggestion s, {
    int? countyCode,
  }) => CustomPlaceDraft(
    name: _clip(s.name, 80),
    address: s.address == null ? null : _clip(s.address!, 200),
    lat: s.lat,
    lng: s.lng,
    source: CustomPlaceSource.search,
    countyCode: countyCode,
  );

  /// A dropped pin the user named.
  factory CustomPlaceDraft.pin({
    required String name,
    required double lat,
    required double lng,
    int? countyCode,
  }) => CustomPlaceDraft(
    name: _clip(name.trim(), 80),
    lat: lat,
    lng: lng,
    source: CustomPlaceSource.pin,
    countyCode: countyCode,
  );

  final String name;
  final String? address;
  final double lat;
  final double lng;
  final CustomPlaceSource source;

  /// Null when the point is outside every county.
  final int? countyCode;

  /// Stable text for telling a result apart from the others on a page.
  String get key => '$lat,$lng,$name';

  static String _clip(String text, int max) =>
      text.length <= max ? text : text.substring(0, max);
}

enum CustomPlaceSource { search, pin }
