import '../domain/journey_device_settings.dart';
import 'journey_capture.dart';

/// Public pre-trip access to the optional device-settings diagnostic.
extension JourneyCaptureDeviceSettings on JourneyCapture {
  /// The phone's power settings now, or null when they cannot be read.
  ///
  /// Device settings are optional and must never block a recording when the
  /// platform source is unavailable.
  Future<JourneyDeviceSettings?> readDeviceSettings() async {
    final source = deviceSettings;
    if (source == null) return null;
    try {
      return await source.read().timeout(const Duration(seconds: 2));
    } on Object {
      return null;
    }
  }
}
