import 'plan_place.dart';

/// A place on a day, in order.
class PlanStop {
  const PlanStop({
    required this.id,
    required this.place,
    this.note,
    this.addedBy,
    this.addedByHandle,
    this.updatedAt,
  });

  final String id;
  final PlanPlace place;
  final String? note;
  final String? addedBy;
  final String? addedByHandle;
  final DateTime? updatedAt;

  static PlanStop? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String) return null;
    final place = PlanPlace.fromJson(json['place']);
    if (place == null) return null;
    String? text(Object? value) =>
        value is String && value.trim().isNotEmpty ? value : null;
    return PlanStop(
      id: json['id'] as String,
      place: place,
      note: text(json['note']),
      addedBy: text(json['added_by']),
      addedByHandle: text(json['added_by_handle']),
      updatedAt: DateTime.tryParse('${json['updated_at']}'),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'place': place.toJson(),
    'note': note,
    'added_by': addedBy,
    'added_by_handle': addedByHandle,
    'updated_at': updatedAt?.toIso8601String(),
  };
}

/// A day of a plan: its stops in order, an optional overnight point, and
/// the last route the app worked out for it.
class PlanDay {
  const PlanDay({
    required this.id,
    required this.number,
    this.title,
    this.stops = const [],
    this.overnightLabel,
    this.overnightLat,
    this.overnightLng,
    this.overnightPlace,
    this.routeStopsKey,
    this.distanceM,
    this.durationS,
    this.countyCodes = const [],
  });

  final String id;

  /// 1 for Day 1.
  final int number;
  final String? title;
  final List<PlanStop> stops;
  final String? overnightLabel;
  final double? overnightLat;
  final double? overnightLng;
  final PlanPlace? overnightPlace;

  /// The stop ids the saved route was worked out for.
  final String? routeStopsKey;
  final int? distanceM;
  final int? durationS;

  /// Counties the saved route passes through.
  final List<int> countyCodes;

  /// The day's stop ids in order, as the server compares route keys.
  String get stopsKey => stops.map((s) => s.id).join(',');

  /// The saved route still matches the stops.
  bool get hasFreshRoute =>
      routeStopsKey != null && routeStopsKey == stopsKey && distanceM != null;

  bool get hasOvernight =>
      overnightPlace != null || (overnightLat != null && overnightLng != null);

  /// "Day 2" or the day's own title.
  String get displayTitle {
    final own = title?.trim();
    return own == null || own.isEmpty ? 'Day $number' : own;
  }

  static PlanDay? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String || json['position'] is! num) {
      return null;
    }
    final stops = json['stops'];
    final counties = json['county_codes'];
    double? number(Object? value) => value is num ? value.toDouble() : null;
    int? whole(Object? value) => value is num ? value.toInt() : null;
    String? text(Object? value) =>
        value is String && value.trim().isNotEmpty ? value : null;
    return PlanDay(
      id: json['id'] as String,
      number: (json['position'] as num).toInt(),
      title: text(json['title']),
      stops: [
        if (stops is List)
          for (final raw in stops)
            ?PlanStop.fromJson(raw),
      ],
      overnightLabel: text(json['overnight_label']),
      overnightLat: number(json['overnight_lat']),
      overnightLng: number(json['overnight_lng']),
      overnightPlace: PlanPlace.fromJson(json['overnight_place']),
      routeStopsKey: text(json['route_stops_key']),
      distanceM: whole(json['distance_m']),
      durationS: whole(json['duration_s']),
      countyCodes: [
        if (counties is List)
          for (final code in counties)
            if (code is num) code.toInt(),
      ],
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'position': number,
    'title': title,
    'stops': [for (final stop in stops) stop.toJson()],
    'overnight_label': overnightLabel,
    'overnight_lat': overnightLat,
    'overnight_lng': overnightLng,
    'overnight_place': overnightPlace?.toJson(),
    'route_stops_key': routeStopsKey,
    'distance_m': distanceM,
    'duration_s': durationS,
    'county_codes': countyCodes,
  };
}
