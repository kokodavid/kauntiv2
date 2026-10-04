import 'public_trip_moment_kind.dart';

/// The owner's share defaults: which moments and photos start switched on
/// in the review screen, and how much of each end of the route is hidden.
/// Changing them never alters a trip that is already public.
class PublicTripSharePreferences {
  const PublicTripSharePreferences({
    required this.countyCrossing,
    required this.elevationPeak,
    required this.topSpeed,
    required this.longStop,
    required this.recordingBreak,
    required this.photos,
    required this.trimMeters,
  });

  /// Places on, anything about the person off, the smallest hidden area.
  static const defaults = PublicTripSharePreferences(
    countyCrossing: true,
    elevationPeak: true,
    topSpeed: false,
    longStop: false,
    recordingBreak: false,
    photos: false,
    trimMeters: 500,
  );

  /// The hidden distances the server accepts, in metres.
  static const trimChoices = [500, 1000, 2000];

  final bool countyCrossing;
  final bool elevationPeak;
  final bool topSpeed;
  final bool longStop;
  final bool recordingBreak;
  final bool photos;
  final int trimMeters;

  bool includes(PublicTripMomentKind kind) => switch (kind) {
    PublicTripMomentKind.countyCrossing => countyCrossing,
    PublicTripMomentKind.elevationPeak => elevationPeak,
    PublicTripMomentKind.topSpeed => topSpeed,
    PublicTripMomentKind.longStop => longStop,
    PublicTripMomentKind.recordingBreak => recordingBreak,
  };

  PublicTripSharePreferences withKind(PublicTripMomentKind kind, bool value) =>
      copyWith(
        countyCrossing: kind == PublicTripMomentKind.countyCrossing
            ? value
            : null,
        elevationPeak: kind == PublicTripMomentKind.elevationPeak
            ? value
            : null,
        topSpeed: kind == PublicTripMomentKind.topSpeed ? value : null,
        longStop: kind == PublicTripMomentKind.longStop ? value : null,
        recordingBreak: kind == PublicTripMomentKind.recordingBreak
            ? value
            : null,
      );

  PublicTripSharePreferences copyWith({
    bool? countyCrossing,
    bool? elevationPeak,
    bool? topSpeed,
    bool? longStop,
    bool? recordingBreak,
    bool? photos,
    int? trimMeters,
  }) => PublicTripSharePreferences(
    countyCrossing: countyCrossing ?? this.countyCrossing,
    elevationPeak: elevationPeak ?? this.elevationPeak,
    topSpeed: topSpeed ?? this.topSpeed,
    longStop: longStop ?? this.longStop,
    recordingBreak: recordingBreak ?? this.recordingBreak,
    photos: photos ?? this.photos,
    trimMeters: trimMeters ?? this.trimMeters,
  );

  factory PublicTripSharePreferences.fromJson(Map<String, dynamic> json) =>
      PublicTripSharePreferences(
        countyCrossing: json['county_crossing'] as bool? ?? true,
        elevationPeak: json['elevation_peak'] as bool? ?? true,
        topSpeed: json['top_speed'] as bool? ?? false,
        longStop: json['long_stop'] as bool? ?? false,
        recordingBreak: json['recording_break'] as bool? ?? false,
        photos: json['photos'] as bool? ?? false,
        trimMeters: (json['trim_m'] as num?)?.toInt() ?? 500,
      );

  @override
  bool operator ==(Object other) =>
      other is PublicTripSharePreferences &&
      other.countyCrossing == countyCrossing &&
      other.elevationPeak == elevationPeak &&
      other.topSpeed == topSpeed &&
      other.longStop == longStop &&
      other.recordingBreak == recordingBreak &&
      other.photos == photos &&
      other.trimMeters == trimMeters;

  @override
  int get hashCode => Object.hash(
    countyCrossing,
    elevationPeak,
    topSpeed,
    longStop,
    recordingBreak,
    photos,
    trimMeters,
  );
}
