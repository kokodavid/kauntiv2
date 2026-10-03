import '../domain/app_feature_flags.dart';
import 'device_battery_reader.dart';
import 'location_diagnostics_store.dart';

abstract final class LocationDiagnostics {
  static bool enabledFor({required bool isDev}) =>
      AppFeatureFlags.locationDiagnostics && isDev;

  static Future<int> batteryPercent() => DeviceBatteryReader.percent();

  static Future<void> start() async {
    if (!AppFeatureFlags.locationDiagnostics) return;
    await LocationDiagnosticsStore.start(
      batteryPercent: await batteryPercent(),
    );
  }

  static Future<void> stop() async {
    if (!AppFeatureFlags.locationDiagnostics) return;
    await LocationDiagnosticsStore.stop(batteryPercent: await batteryPercent());
  }

  static Future<void> record(
    String event, [
    Map<String, Object?> data = const {},
  ]) async {
    if (!AppFeatureFlags.locationDiagnostics) return;
    try {
      await LocationDiagnosticsStore.record(event, data);
    } on Object {
      // Diagnostic I/O must never interrupt location or journey behavior.
    }
  }

  static Future<bool> isActive() async {
    if (!AppFeatureFlags.locationDiagnostics) return false;
    return LocationDiagnosticsStore.isActive();
  }

  static Future<String?> summary() async {
    if (!AppFeatureFlags.locationDiagnostics) return null;
    return LocationDiagnosticsStore.summary();
  }

  static Future<String?> reportPath() async {
    if (!AppFeatureFlags.locationDiagnostics) return null;
    return (await LocationDiagnosticsStore.latestReport())?.path;
  }

  static Future<void> clear() async {
    if (!AppFeatureFlags.locationDiagnostics) return;
    await LocationDiagnosticsStore.clear();
  }
}
