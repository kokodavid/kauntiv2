import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_device_settings.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_pause_reason.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_quality.dart';

void main() {
  test('counts pauses by reason and separates system pauses', () {
    final quality = const JourneyQuality()
        .withPause(JourneyPauseReason.user)
        .withPause(JourneyPauseReason.locationLost)
        .withPause(JourneyPauseReason.locationLost)
        .withPause(JourneyPauseReason.appRestarted);

    expect(quality.userPauses, 1);
    expect(quality.systemPauses, 3);
    expect(quality.pausesByReason['location_lost'], 2);
  });

  test('round-trips through JSON text', () {
    final quality = const JourneyQuality(
      gaps: 2,
      gapMillis: 240000,
      fixesAccepted: 500,
      spikesDropped: 3,
      jumpsAccepted: 1,
      streamLosses: 4,
      streamRecoveries: 3,
      lostMillis: 90000,
      settings: const JourneyDeviceSettings(batteryPercent: 80),
      // Read again right before the pause, so this can differ from
      // [settings] above -- here, battery saver switched on partway
      // through the Trip.
      settingsAtPause: const JourneyDeviceSettings(
        batterySaver: true,
        batteryPercent: 14,
      ),
    ).withPause(JourneyPauseReason.locationLost);

    final decoded = JourneyQuality.decode(quality.encode());

    expect(decoded, isNotNull);
    expect(decoded!.toJson(), quality.toJson());
    expect(decoded.settingsAtPause?.batterySaver, true);
  });

  test('missing or unreadable text decodes to null', () {
    expect(JourneyQuality.decode(null), isNull);
    expect(JourneyQuality.decode(''), isNull);
    expect(JourneyQuality.decode('not json'), isNull);
    expect(JourneyQuality.decode('[1, 2]'), isNull);
  });

  test('bad values in saved text are ignored, not trusted', () {
    final decoded = JourneyQuality.decode(
      '{"gaps": -3, "spikes_dropped": "x", "fixes_accepted": 7, '
      '"pauses": {"user": 2, "location_lost": -1}}',
    );

    expect(decoded!.gaps, 0);
    expect(decoded.spikesDropped, 0);
    expect(decoded.fixesAccepted, 7);
    expect(decoded.pausesByReason, {'user': 2});
  });
}
