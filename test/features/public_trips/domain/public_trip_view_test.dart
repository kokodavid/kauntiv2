import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_moment_kind.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_view.dart';

Map<String, dynamic> _json() => {
  'id': 'pub-1',
  'revision': 2,
  'title': 'Naivasha loop',
  'trip_date': '2026-09-25',
  'transport_mode': 'walk',
  'distance_m': 5200,
  'author': {
    'id': 'a1',
    'display_name': 'Wanjiru',
    'handle': 'wanjiru',
    'avatar_url': 'https://example.invalid/a.png',
  },
  'counties': [
    {'code': 47, 'name': 'Nairobi'},
    {'code': 32, 'name': 'Nakuru'},
  ],
  'route': {
    'type': 'MultiLineString',
    'coordinates': [
      [
        [36.8, -1.3],
        [36.9, -1.2],
      ],
      [
        [37.0, -1.1],
        [37.1, -1.0],
      ],
    ],
  },
  'moments': [
    {'kind': 'county_crossing', 'latitude': -1.2, 'longitude': 36.9},
    {'kind': 'teleport', 'latitude': 0.0, 'longitude': 0.0},
  ],
  'photos': [
    {'id': 'ph-1', 'latitude': -1.25, 'longitude': 36.85, 'width': 1200},
    {'id': 'ph-2'},
  ],
  'unclaimed_counties': 1,
};

void main() {
  test('reads the route as separate lines, longitude first', () {
    final trip = PublicTripView.fromJson(_json());
    expect(trip.routeLines, hasLength(2));
    expect(trip.routeLines.first.first.latitude, -1.3);
    expect(trip.routeLines.first.first.longitude, 36.8);
  });

  test('the public start is the first point of the trimmed route', () {
    final trip = PublicTripView.fromJson(_json());
    expect(trip.publicStart?.latitude, -1.3);
    expect(trip.publicStart?.longitude, 36.8);
  });

  test('has no public start when the route is empty', () {
    final json = _json()..['route'] = {'coordinates': <Object>[]};
    expect(PublicTripView.fromJson(json).publicStart, isNull);
  });

  test('skips moment kinds this app does not know', () {
    final trip = PublicTripView.fromJson(_json());
    expect(trip.moments, hasLength(1));
    expect(trip.moments.single.kind, PublicTripMomentKind.countyCrossing);
  });

  test('photos may lack a place', () {
    final trip = PublicTripView.fromJson(_json());
    expect(trip.photos.first.hasPlace, isTrue);
    expect(trip.photos.last.hasPlace, isFalse);
  });

  test('reads the author, mode and the new-for-you count', () {
    final trip = PublicTripView.fromJson(_json());
    expect(trip.author.displayName, 'Wanjiru');
    expect(trip.author.handle, 'wanjiru');
    expect(trip.isWalk, isTrue);
    expect(trip.unclaimedCounties, 1);
    expect(trip.counties.map((c) => c.name), ['Nairobi', 'Nakuru']);
  });

  test('falls back to a friendly author name', () {
    final json = _json()..['author'] = {'id': 'a1', 'display_name': '  '};
    expect(
      PublicTripView.fromJson(json).author.displayName,
      'A Kaunti47 explorer',
    );
  });
}
