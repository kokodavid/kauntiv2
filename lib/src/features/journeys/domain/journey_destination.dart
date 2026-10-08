import 'dart:convert';

/// A place the Trip is meant to pass on the way to its destination.
class JourneyStop {
  const JourneyStop({
    required this.placeId,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String placeId;
  final String name;
  final double latitude;
  final double longitude;

  bool get isValid =>
      placeId.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      name.trim().length <= 160 &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  Map<String, Object> toJson() => {
    'place_id': placeId,
    'name': name,
    'lat': latitude,
    'lng': longitude,
  };

  static JourneyStop? fromJson(Object? json) {
    if (json is! Map) return null;
    final placeId = json['place_id'];
    final name = json['name'];
    final lat = json['lat'];
    final lng = json['lng'];
    if (placeId is! String || name is! String) return null;
    if (lat is! num || lng is! num) return null;
    return JourneyStop(
      placeId: placeId,
      name: name,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
    );
  }

  /// Stops stored as JSON text (local database) or a decoded list
  /// (Supabase `jsonb`). Anything unreadable is skipped.
  static List<JourneyStop> listFrom(Object? raw) {
    Object? decoded = raw;
    if (raw is String) {
      if (raw.isEmpty) return const [];
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        return const [];
      }
    }
    if (decoded is! List) return const [];
    return [for (final item in decoded) ?fromJson(item)];
  }

  static String encodeList(List<JourneyStop> stops) =>
      jsonEncode([for (final stop in stops) stop.toJson()]);
}

/// A place chosen before recording. The snapshot stays useful if the place
/// listing changes or is removed later.
///
/// [viaStops] are the places planned on the way, in order, before this
/// destination. They are a record of the plan; badges still come only from
/// where the Trip actually goes.
class JourneyDestination {
  const JourneyDestination({
    required this.placeId,
    required this.name,
    this.latitude,
    this.longitude,
    this.viaStops = const [],
  });

  /// More than this and the planner and the server both refuse.
  static const maxViaStops = 6;

  final String placeId;
  final String name;
  final double? latitude;
  final double? longitude;
  final List<JourneyStop> viaStops;

  bool get isValid =>
      placeId.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      name.trim().length <= 160 &&
      ((latitude == null && longitude == null) ||
          (latitude != null &&
              longitude != null &&
              latitude!.isFinite &&
              longitude!.isFinite &&
              latitude! >= -90 &&
              latitude! <= 90 &&
              longitude! >= -180 &&
              longitude! <= 180)) &&
      viaStops.length <= maxViaStops &&
      viaStops.every((stop) => stop.isValid);
}
