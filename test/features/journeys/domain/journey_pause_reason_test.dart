import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_pause_reason.dart';

void main() {
  test('only app-made pauses count as system pauses', () {
    expect(JourneyPauseReason.user.isSystem, isFalse);
    expect(JourneyPauseReason.unknown.isSystem, isFalse);
    expect(JourneyPauseReason.locationLost.isSystem, isTrue);
    expect(JourneyPauseReason.appRestarted.isSystem, isTrue);
    expect(JourneyPauseReason.startFailed.isSystem, isTrue);
    expect(JourneyPauseReason.accountChanged.isSystem, isTrue);
  });

  test('storage values round-trip', () {
    for (final reason in JourneyPauseReason.values) {
      expect(JourneyPauseReason.fromStorage(reason.storageValue), reason);
    }
  });

  test('missing or unrecognised storage values are handled', () {
    expect(JourneyPauseReason.fromStorage(null), isNull);
    expect(
      JourneyPauseReason.fromStorage('something_new'),
      JourneyPauseReason.unknown,
    );
  });
}
