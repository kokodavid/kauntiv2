import '../../../core/domain/map_place.dart';
import '../../../counties/county_paths.dart';
import 'map_home_models.dart';
import 'map_home_nearby_places.dart';

/// What a carousel card is. A new kind ("Go back", "Trip again") registers
/// here and gets a card the same way.
enum MapHomeNearbyKind { place, newCounty }

/// One card in the collapsed sheet's carousel.
class MapHomeNearbyCard {
  const MapHomeNearbyCard({
    required this.kind,
    required this.pill,
    required this.title,
    required this.subtitle,
    required this.county,
    this.distanceValue,
    this.distanceUnit,
    this.imageUrl,
    this.place,
  });

  final MapHomeNearbyKind kind;

  /// The small label on the photo: "New county", "Waterfall".
  final String pill;
  final String title;
  final String subtitle;
  final CountyPath county;

  /// "66" and "km"; null when the distance is not known.
  final String? distanceValue;
  final String? distanceUnit;
  final String? imageUrl;

  /// The place a [MapHomeNearbyKind.place] card opens.
  final MapPlace? place;
}

abstract final class MapHomeNearbyCards {
  /// The most cards the carousel holds.
  static const maxCards = 6;

  /// Places and counties alternate, nearest first, so the first swipe is
  /// not all one kind. Counties come from the board and are there at once;
  /// [places] join when they have loaded.
  static List<MapHomeNearbyCard> build({
    required List<MapHomeSuggestion> unclaimed,
    required Map<int, int> placeCounts,
    List<MapHomeNearbyPlace> places = const [],
  }) {
    final placeCards = [for (final p in places) _place(p)];
    final countyCards = [
      for (final s in unclaimed) _county(s, placeCounts[s.county.code] ?? 0),
    ];
    final out = <MapHomeNearbyCard>[];
    var i = 0;
    while (out.length < maxCards &&
        (i < placeCards.length || i < countyCards.length)) {
      if (i < placeCards.length) out.add(placeCards[i]);
      if (out.length < maxCards && i < countyCards.length) {
        out.add(countyCards[i]);
      }
      i++;
    }
    return out;
  }

  static MapHomeNearbyCard _place(MapHomeNearbyPlace entry) {
    final distance = splitDistance(entry.distanceLabel);
    final type = _capitalise(entry.place.type);
    return MapHomeNearbyCard(
      kind: MapHomeNearbyKind.place,
      pill: type.isEmpty ? 'Place near you' : type,
      title: entry.place.name,
      subtitle: type.isEmpty
          ? entry.county.name
          : '${entry.county.name} · $type',
      county: entry.county,
      distanceValue: distance?.value,
      distanceUnit: distance?.unit,
      imageUrl: entry.place.thumbnailUrl,
      place: entry.place,
    );
  }

  static MapHomeNearbyCard _county(MapHomeSuggestion s, int placeCount) {
    final distance = splitDistance(s.distanceAway);
    return MapHomeNearbyCard(
      kind: MapHomeNearbyKind.newCounty,
      pill: 'New county',
      title: s.county.name,
      subtitle: placeCount > 0
          ? 'Unclaimed · $placeCount ${placeCount == 1 ? 'place' : 'places'}'
          : 'Unclaimed',
      county: s.county,
      distanceValue: distance?.value,
      distanceUnit: distance?.unit,
      imageUrl: s.highlightImageUrl,
    );
  }

  /// "66 km away" -> (66, km); "4.2 km" -> (4.2, km); "Nearby" -> null.
  static ({String value, String unit})? splitDistance(String label) {
    final match = RegExp(r'^(\d+(?:\.\d+)?)\s*(km|m)\b').firstMatch(label);
    if (match == null) return null;
    return (value: match.group(1)!, unit: match.group(2)!);
  }

  static String _capitalise(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
