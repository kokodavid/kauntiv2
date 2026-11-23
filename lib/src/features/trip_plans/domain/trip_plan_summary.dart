import 'plan_member.dart';

/// A day as a plan card needs it: totals from the saved route and the stop
/// points for the route-shape thumbnail.
class PlanDaySummary {
  const PlanDaySummary({
    required this.number,
    this.distanceM,
    this.durationS,
    this.countyCodes = const [],
    this.routeFresh = false,
    this.points = const [],
  });

  final int number;
  final int? distanceM;
  final int? durationS;
  final List<int> countyCodes;
  final bool routeFresh;

  /// Stop positions in order, as (lat, lng).
  final List<(double, double)> points;

  static PlanDaySummary? fromJson(Object? json) {
    if (json is! Map || json['position'] is! num) return null;
    final counties = json['county_codes'];
    final points = json['points'];
    return PlanDaySummary(
      number: (json['position'] as num).toInt(),
      distanceM: _whole(json['distance_m']),
      durationS: _whole(json['duration_s']),
      routeFresh: json['route_fresh'] == true,
      countyCodes: [
        if (counties is List)
          for (final code in counties)
            if (code is num) code.toInt(),
      ],
      points: [
        if (points is List)
          for (final point in points)
            if (point is List &&
                point.length == 2 &&
                point[0] is num &&
                point[1] is num)
              ((point[0] as num).toDouble(), (point[1] as num).toDouble()),
      ],
    );
  }

  static int? _whole(Object? value) => value is num ? value.toInt() : null;

  Map<String, Object?> toJson() => {
    'position': number,
    'distance_m': distanceM,
    'duration_s': durationS,
    'county_codes': countyCodes,
    'route_fresh': routeFresh,
    'points': [
      for (final (lat, lng) in points) [lat, lng],
    ],
  };
}

/// A plan in the Planned list (`list_trip_plans`).
class TripPlanSummary {
  const TripPlanSummary({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.role,
    this.startDate,
    this.archived = false,
    this.converted = false,
    this.muted = false,
    this.isPast = false,
    this.updatedAt,
    this.members = const [],
    this.days = const [],
  });

  final String id;
  final String title;
  final String ownerId;
  final PlanRole role;
  final DateTime? startDate;
  final bool archived;
  final bool converted;
  final bool muted;
  final bool isPast;
  final DateTime? updatedAt;
  final List<PlanMember> members;
  final List<PlanDaySummary> days;

  bool get isOwn => role == PlanRole.owner;
  bool get isShared => members.length > 1;
  int get dayCount => days.length;

  DateTime? get endDate => startDate == null || days.isEmpty
      ? startDate
      : startDate!.add(Duration(days: days.length - 1));

  /// Every county the saved routes pass through, once each, in day order.
  List<int> get countyCodes {
    final seen = <int>{};
    return [
      for (final day in days)
        for (final code in day.countyCodes)
          if (seen.add(code)) code,
    ];
  }

  /// Whether some days have no saved route yet, so county counts are
  /// incomplete.
  bool get hasMissingRoutes => days.any((d) => !d.routeFresh);

  /// Who shared this plan with the signed-in user, for "From mwangi_j".
  PlanMember? get owner {
    for (final member in members) {
      if (member.role == PlanRole.owner) return member;
    }
    return null;
  }

  static TripPlanSummary? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String || json['title'] is! String) {
      return null;
    }
    final members = json['members'];
    final days = json['days'];
    return TripPlanSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      ownerId: '${json['owner_id']}',
      role: PlanRole.parse(json['role']),
      startDate: DateTime.tryParse('${json['start_date']}'),
      archived: json['archived'] == true,
      converted: json['converted'] == true,
      muted: json['muted'] == true,
      isPast: json['is_past'] == true,
      updatedAt: DateTime.tryParse('${json['updated_at']}'),
      members: [
        if (members is List)
          for (final raw in members) ?PlanMember.fromJson(raw),
      ],
      days: [
        if (days is List)
          for (final raw in days) ?PlanDaySummary.fromJson(raw),
      ]..sort((a, b) => a.number.compareTo(b.number)),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'owner_id': ownerId,
    'role': role.name,
    'start_date': startDate?.toIso8601String().substring(0, 10),
    'archived': archived,
    'converted': converted,
    'muted': muted,
    'is_past': isPast,
    'updated_at': updatedAt?.toIso8601String(),
    'members': [for (final member in members) member.toJson()],
    'days': [for (final day in days) day.toJson()],
  };
}
