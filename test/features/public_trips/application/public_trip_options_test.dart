import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_media_capture.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_moments.dart';
import 'package:kaunti47_v2/src/features/public_trips/application/public_trip_options.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_moment_kind.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_share_preferences.dart';

JourneyMoment _county(int index, String name) => JourneyMoment(
  kind: JourneyMomentKind.countyCrossing,
  index: index,
  name: name,
);

void main() {
  final moments = [
    _county(5, 'Kiambu'),
    const JourneyMoment(
      kind: JourneyMomentKind.topSpeed,
      index: 9,
      speedMetersPerSecond: 25,
    ),
    JourneyMoment(
      kind: JourneyMomentKind.photo,
      index: 11,
      photo: JourneyMediaItem(
        id: 'm1',
        url: 'https://example.invalid/m1',
        capturedAt: DateTime.utc(2026, 9, 25),
      ),
    ),
    const JourneyMoment(
      kind: JourneyMomentKind.longStop,
      index: 14,
      duration: Duration(minutes: 25),
    ),
  ];

  test('options skip photo moments and describe the others', () {
    final options = publicTripMomentOptions(moments);
    expect(options.map((o) => o.kind), [
      PublicTripMomentKind.countyCrossing,
      PublicTripMomentKind.topSpeed,
      PublicTripMomentKind.longStop,
    ]);
    expect(options[0].detail, 'Entered Kiambu');
    expect(options[1].detail, '90 km/h');
    expect(options[2].detail, '25 min');
    expect(options[0].sequenceNumber, 5);
    expect(options[0].key, 'county_crossing:5');
  });

  test('default moments follow the share defaults', () {
    final options = publicTripMomentOptions(moments);
    expect(
      publicTripDefaultMoments(options, PublicTripSharePreferences.defaults),
      {'county_crossing:5'},
    );
  });

  test('only located photos are offered; none are chosen by default', () {
    final media = [
      JourneyMediaItem(
        id: 'a',
        url: 'u',
        capturedAt: DateTime.utc(2026),
        latitude: -1,
        longitude: 36,
      ),
      JourneyMediaItem(id: 'b', url: 'u', capturedAt: DateTime.utc(2026)),
    ];
    final options = publicTripPhotoOptions(media);
    expect(options.map((o) => o.id), ['a']);
    expect(
      publicTripDefaultPhotos(options, PublicTripSharePreferences.defaults),
      isEmpty,
    );
    expect(
      publicTripDefaultPhotos(
        options,
        PublicTripSharePreferences.defaults.copyWith(photos: true),
      ),
      {'a'},
    );
  });

  test('saving choices as defaults only learns from kinds on the trip', () {
    final options = publicTripMomentOptions(moments);
    final prefs = publicTripPreferencesFromChoices(
      base: PublicTripSharePreferences.defaults,
      options: options,
      selectedMoments: {'top_speed:9'},
      selectedPhotos: {'a'},
      trimMeters: 1000,
    );
    expect(prefs.topSpeed, isTrue);
    expect(prefs.countyCrossing, isFalse); // On the trip, switched off.
    expect(prefs.elevationPeak, isTrue); // Not on the trip: unchanged.
    expect(prefs.photos, isTrue);
    expect(prefs.trimMeters, 1000);
  });
}
