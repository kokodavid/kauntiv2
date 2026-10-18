import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/notifications/domain/push_destination.dart';

void main() {
  group('PushDestination.fromData', () {
    test('reads a county destination with its id', () {
      final d = PushDestination.fromData({
        'dest_kind': 'county',
        'dest_id': '22',
      });
      expect(d.kind, PushDestinationKind.county);
      expect(d.id, '22');
    });

    test('maps my_photos and treats an empty id as none', () {
      final d = PushDestination.fromData({
        'dest_kind': 'my_photos',
        'dest_id': '',
      });
      expect(d.kind, PushDestinationKind.myPhotos);
      expect(d.id, isNull);
    });

    test('an unknown or missing kind opens Home', () {
      expect(
        PushDestination.fromData({'dest_kind': 'from_the_future'}).kind,
        PushDestinationKind.home,
      );
      expect(PushDestination.fromData({}).kind, PushDestinationKind.home);
    });
  });

  group('PushTap.fromData', () {
    test('keeps the event id for open tracking', () {
      final tap = PushTap.fromData({
        'event_id': 'abc',
        'dest_kind': 'badges',
      });
      expect(tap.eventId, 'abc');
      expect(tap.destination.kind, PushDestinationKind.badges);
    });

    test('an empty event id is none', () {
      expect(PushTap.fromData({'event_id': ''}).eventId, isNull);
    });
  });

  group('FirebaseSettings.isConfigured', () {
    test('is false when anything essential is missing', () {
      const empty = FirebaseSettings(
        projectId: '',
        apiKey: '',
        messagingSenderId: '',
        androidAppId: '',
        iosAppId: '',
      );
      expect(empty.isConfigured, isFalse);
    });

    test('is true with a project, key, sender and one app id', () {
      const android = FirebaseSettings(
        projectId: 'p',
        apiKey: 'k',
        messagingSenderId: '1',
        androidAppId: 'a',
        iosAppId: '',
      );
      expect(android.isConfigured, isTrue);
    });
  });
}
