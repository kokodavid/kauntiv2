import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_moment_kind.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_owner_view.dart';

import '../fake_public_trip_repository.dart';

void main() {
  test('parses the server preview', () {
    final view = PublicTripOwnerView.fromJson({
      'id': 'p1',
      'status': 'prepared',
      'revision': 2,
      'title': 'Morning drive',
      'trip_date': '2026-09-25',
      'transport_mode': 'drive',
      'distance_m': 12400.5,
      'counties': [
        {'code': 47, 'name': 'Nairobi'},
      ],
      'route': {
        'type': 'MultiLineString',
        'coordinates': [
          [
            [36.82, -1.30],
            [36.83, -1.29],
          ],
        ],
      },
      'moments': [
        {
          'kind': 'top_speed',
          'latitude': -1.3,
          'longitude': 36.8,
          'value': <String, dynamic>{},
        },
        {
          'kind': 'unknown_kind',
          'latitude': 0,
          'longitude': 0,
          'value': <String, dynamic>{},
        },
      ],
      'photos': [
        {'id': 'a'},
      ],
      'photos_pending': 1,
      'photos_failed': 0,
      'content_hash': 'h',
      'expires_at': '2099-01-01T00:00:00Z',
      'excluded': {
        'moments': [
          {'kind': 'long_stop'},
        ],
        'photo_ids': ['x', 'y'],
      },
      'start_trim_m': 1000,
      'end_trim_m': 1000,
    });
    expect(view.revision, 2);
    expect(view.routeLines.single.first.latitude, -1.30);
    expect(view.routeLines.single.first.longitude, 36.82);
    expect(view.moments.single.kind, PublicTripMomentKind.topSpeed);
    expect(view.photoCount, 1);
    expect(view.photosReady, isFalse);
    expect(view.excludedMomentCount, 1);
    expect(view.excludedPhotoCount, 2);
    expect(view.isExpired, isFalse);
    expect(view.hasPreview, isTrue);
  });

  test('a withdrawn trip carries only its id and status', () {
    final view = PublicTripOwnerView.fromJson({
      'id': 'p1',
      'status': 'revoked',
      'active_revision': null,
      'hidden': false,
    });
    expect(view.phase, PublicTripPhase.none);
    expect(view.hasPreview, isFalse);
  });

  group('phase', () {
    test('submitted is awaiting review', () {
      expect(
        ownerView(status: PublicTripStatus.submitted).phase,
        PublicTripPhase.awaitingReview,
      );
    });

    test('a live revision is public, even with a newer one in review', () {
      final view = ownerView(
        status: PublicTripStatus.submitted,
        revision: 2,
        activeRevision: 1,
      );
      expect(view.phase, PublicTripPhase.isPublic);
      expect(view.hasPendingChange, isTrue);
    });

    test('rejected needs changes', () {
      expect(
        ownerView(status: PublicTripStatus.rejected).phase,
        PublicTripPhase.needsChanges,
      );
    });

    test('hidden wins over everything', () {
      expect(
        ownerView(
          status: PublicTripStatus.approved,
          activeRevision: 1,
          hidden: true,
        ).phase,
        PublicTripPhase.hidden,
      );
    });

    test('a prepared draft is not a public state', () {
      expect(ownerView().phase, PublicTripPhase.none);
    });
  });
}
