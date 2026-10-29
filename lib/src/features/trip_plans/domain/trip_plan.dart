import 'plan_day.dart';
import 'plan_limits.dart';
import 'plan_member.dart';
import 'plan_place.dart';

/// Where Day 1 starts.
enum PlanStartKind {
  currentLocation,
  place,
  point;

  String get wire => switch (this) {
    currentLocation => 'current_location',
    place => 'place',
    point => 'point',
  };

  static PlanStartKind parse(Object? value) => switch (value) {
    'place' => place,
    'point' => point,
    _ => currentLocation,
  };
}

class PlanStart {
  const PlanStart({
    required this.kind,
    this.label,
    this.lat,
    this.lng,
    this.place,
  });

  static const currentLocation = PlanStart(kind: PlanStartKind.currentLocation);

  final PlanStartKind kind;
  final String? label;
  final double? lat;
  final double? lng;
  final PlanPlace? place;

  /// "Westlands, Nairobi"; "Where you are" for the phone's location.
  String get displayLabel => switch (kind) {
    PlanStartKind.currentLocation => 'Where you are',
    _ => label ?? place?.name ?? 'Chosen point',
  };
}

/// A place on Places to visit (not on a day yet).
class PlanIdea {
  const PlanIdea({required this.place, this.note, this.addedByHandle});

  final PlanPlace place;
  final String? note;
  final String? addedByHandle;

  static PlanIdea? fromJson(Object? json) {
    if (json is! Map) return null;
    final place = PlanPlace.fromJson(json['place']);
    if (place == null) return null;
    final note = json['note'];
    final by = json['added_by_handle'];
    return PlanIdea(
      place: place,
      note: note is String && note.trim().isNotEmpty ? note : null,
      addedByHandle: by is String ? by : null,
    );
  }

  Map<String, Object?> toJson() => {
    'place': place.toJson(),
    'note': note,
    'added_by_handle': addedByHandle,
  };
}

/// One plan as the plan screen shows it (`get_trip_plan`).
class TripPlan {
  const TripPlan({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.role,
    required this.start,
    required this.limits,
    this.startDate,
    this.archived = false,
    this.converted = false,
    this.updatedAt,
    this.updatedByHandle,
    this.days = const [],
    this.places = const [],
    this.members = const [],
  });

  final String id;
  final String title;
  final String ownerId;

  /// The signed-in user's role in this plan.
  final PlanRole role;
  final PlanStart start;
  final PlanLimits limits;
  final DateTime? startDate;
  final bool archived;
  final bool converted;
  final DateTime? updatedAt;
  final String? updatedByHandle;
  final List<PlanDay> days;
  final List<PlanIdea> places;
  final List<PlanMember> members;

  bool get canEdit => role.canEdit;
  bool get isShared => members.where((m) => m.joined).length > 1;

  /// The date of the last day, or null for an undated plan.
  DateTime? get endDate => startDate == null || days.isEmpty
      ? startDate
      : startDate!.add(Duration(days: days.length - 1));

  /// Day [day]'s date, or null for an undated plan.
  DateTime? dateOf(PlanDay day) =>
      startDate?.add(Duration(days: day.number - 1));

  static TripPlan? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String || json['title'] is! String) {
      return null;
    }
    double? number(Object? value) => value is num ? value.toDouble() : null;
    final label = json['start_label'];
    final days = json['days'];
    final places = json['places'];
    final members = json['members'];
    final by = json['updated_by_handle'];
    return TripPlan(
      id: json['id'] as String,
      title: json['title'] as String,
      ownerId: '${json['owner_id']}',
      role: PlanRole.parse(json['role']),
      start: PlanStart(
        kind: PlanStartKind.parse(json['start_kind']),
        label: label is String ? label : null,
        lat: number(json['start_lat']),
        lng: number(json['start_lng']),
        place: PlanPlace.fromJson(json['start_place']),
      ),
      limits: PlanLimits.fromJson(json['limits']),
      startDate: DateTime.tryParse('${json['start_date']}'),
      archived: json['archived'] == true,
      converted: json['converted'] == true,
      updatedAt: DateTime.tryParse('${json['updated_at']}'),
      updatedByHandle: by is String ? by : null,
      days: [
        if (days is List)
          for (final raw in days)
            ?PlanDay.fromJson(raw),
      ]..sort((a, b) => a.number.compareTo(b.number)),
      places: [
        if (places is List)
          for (final raw in places)
            ?PlanIdea.fromJson(raw),
      ],
      members: [
        if (members is List)
          for (final raw in members)
            ?PlanMember.fromJson(raw),
      ],
    );
  }

  /// The same shape as `get_trip_plan`, for the copy kept on the phone.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'owner_id': ownerId,
    'role': role.name,
    'start_kind': start.kind.wire,
    'start_label': start.label,
    'start_lat': start.lat,
    'start_lng': start.lng,
    'start_place': start.place?.toJson(),
    'limits': limits.toJson(),
    'start_date': startDate == null ? null : _date(startDate!),
    'archived': archived,
    'converted': converted,
    'updated_at': updatedAt?.toIso8601String(),
    'updated_by_handle': updatedByHandle,
    'days': [for (final day in days) day.toJson()],
    'places': [for (final idea in places) idea.toJson()],
    'members': [for (final member in members) member.toJson()],
  };

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
