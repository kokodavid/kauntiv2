import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_device_settings.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_quality.dart';

void main() {
  test('unknown settings give no warnings', () {
    expect(const JourneyDeviceSettings().warnings, isEmpty);
  });

  test('battery saver and a low battery are warned about', () {
    expect(
      const JourneyDeviceSettings(batterySaver: true).warnings,
      [JourneySettingsWarning.batterySaver],
    );
    expect(
      const JourneyDeviceSettings(batteryPercent: 10).warnings,
      [JourneySettingsWarning.lowBattery],
    );
    expect(const JourneyDeviceSettings(batteryPercent: 15).warnings, isEmpty);
  });

  test('battery optimisation only warns on strict makers', () {
    expect(
      const JourneyDeviceSettings(batteryOptimised: true).warnings,
      isEmpty,
    );
    expect(
      const JourneyDeviceSettings(
        batteryOptimised: true,
        strictMaker: true,
      ).warnings,
      [JourneySettingsWarning.batteryOptimisation],
    );
    expect(
      const JourneyDeviceSettings(
        batteryOptimised: false,
        strictMaker: true,
      ).warnings,
      isEmpty,
    );
  });

  test('round-trips through JSON and ignores bad values', () {
    const settings = JourneyDeviceSettings(
      batterySaver: true,
      batteryOptimised: false,
      batteryPercent: 42,
      strictMaker: true,
    );
    final decoded = JourneyDeviceSettings.fromJson(settings.toJson());
    expect(decoded?.toJson(), settings.toJson());

    final bad = JourneyDeviceSettings.fromJson({
      'battery_saver': 'yes',
      'battery_percent': 500,
    });
    expect(bad?.batterySaver, isNull);
    expect(bad?.batteryPercent, isNull);
    expect(JourneyDeviceSettings.fromJson('nope'), isNull);
  });

  test('the quality summary carries the settings snapshot', () {
    final quality = const JourneyQuality().copyWith(
      settings: const JourneyDeviceSettings(batterySaver: true),
    );
    final decoded = JourneyQuality.decode(quality.encode());
    expect(decoded?.settings?.batterySaver, isTrue);
  });
}
