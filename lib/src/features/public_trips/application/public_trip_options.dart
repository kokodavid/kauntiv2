import '../../journeys/domain/journey_media_capture.dart';
import '../../journeys/domain/journey_moments.dart';
import '../domain/public_trip_moment_kind.dart';
import '../domain/public_trip_share_preferences.dart';
import 'public_trip_review_state.dart';

/// Turns a trip's replay moments into the choices the owner sees. Photo
/// moments are skipped: photos are chosen on their own.
List<PublicTripMomentOption> publicTripMomentOptions(
  List<JourneyMoment> moments,
) {
  final options = <PublicTripMomentOption>[];
  for (final moment in moments) {
    final kind = _kindOf(moment.kind);
    if (kind == null) continue;
    options.add(
      PublicTripMomentOption(
        kind: kind,
        sequenceNumber: moment.index,
        detail: _detailOf(kind, moment),
      ),
    );
  }
  return options;
}

/// Only photos with a location can be placed on a public route.
List<PublicTripPhotoOption> publicTripPhotoOptions(
  List<JourneyMediaItem> media,
) => [
  for (final item in media)
    if (item.latitude != null && item.longitude != null)
      PublicTripPhotoOption(id: item.id, url: item.url),
];

/// The moments switched on at first: every kind the owner's defaults allow.
Set<String> publicTripDefaultMoments(
  List<PublicTripMomentOption> options,
  PublicTripSharePreferences preferences,
) => {
  for (final option in options)
    if (preferences.includes(option.kind)) option.key,
};

/// Photos start off unless the owner's defaults say to include them.
Set<String> publicTripDefaultPhotos(
  List<PublicTripPhotoOption> options,
  PublicTripSharePreferences preferences,
) => preferences.photos
    ? {for (final option in options.take(publicTripMaxPhotos)) option.id}
    : <String>{};

/// The defaults that match what the owner chose: a kind is "on" when any
/// moment of that kind is switched on.
PublicTripSharePreferences publicTripPreferencesFromChoices({
  required PublicTripSharePreferences base,
  required List<PublicTripMomentOption> options,
  required Set<String> selectedMoments,
  required Set<String> selectedPhotos,
  required int trimMeters,
}) {
  var result = base.copyWith(
    photos: selectedPhotos.isNotEmpty,
    trimMeters: trimMeters,
  );
  for (final kind in PublicTripMomentKind.values) {
    final ofKind = options.where((option) => option.kind == kind);
    if (ofKind.isEmpty) continue; // Nothing to learn from this trip.
    result = result.withKind(
      kind,
      ofKind.any((option) => selectedMoments.contains(option.key)),
    );
  }
  return result;
}

PublicTripMomentKind? _kindOf(JourneyMomentKind kind) => switch (kind) {
  JourneyMomentKind.recordingBreak => PublicTripMomentKind.recordingBreak,
  JourneyMomentKind.longStop => PublicTripMomentKind.longStop,
  JourneyMomentKind.countyCrossing => PublicTripMomentKind.countyCrossing,
  JourneyMomentKind.elevationPeak => PublicTripMomentKind.elevationPeak,
  JourneyMomentKind.topSpeed => PublicTripMomentKind.topSpeed,
  JourneyMomentKind.photo => null,
};

String _detailOf(PublicTripMomentKind kind, JourneyMoment moment) {
  switch (kind) {
    case PublicTripMomentKind.countyCrossing:
      final name = moment.name;
      return name == null ? 'Entered a new county' : 'Entered $name';
    case PublicTripMomentKind.elevationPeak:
      final meters = moment.elevationMeters;
      return meters == null ? '' : '${meters.round()} m above sea level';
    case PublicTripMomentKind.topSpeed:
      final speed = moment.speedMetersPerSecond;
      return speed == null ? '' : '${(speed * 3.6).round()} km/h';
    case PublicTripMomentKind.longStop:
    case PublicTripMomentKind.recordingBreak:
      final duration = moment.duration;
      if (duration == null) return '';
      final minutes = duration.inMinutes;
      return minutes < 1 ? 'Under a minute' : '$minutes min';
  }
}
