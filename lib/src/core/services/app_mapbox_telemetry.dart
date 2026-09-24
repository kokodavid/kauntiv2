import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../services/app_logger.dart';

/// Keeps Mapbox's location telemetry off by default (doc 05: precise
/// location stays on the device). Users can still opt in from the map's
/// (i) attribution menu, which Mapbox's terms require us to keep visible.
///
/// iOS applies this at launch in `AppDelegate`. Android needs Mapbox's
/// native library loaded first, so the real map calls [applyPrivacyDefault]
/// once it's created; the native side only acts on the first call ever.
abstract final class AppMapboxTelemetry {
  static const _channel = MethodChannel('com.giglab.kaunti47/mapbox');
  static const _logger = AppLogger.mapHome();

  static Future<void> applyPrivacyDefault() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final applied = await _channel.invokeMethod<bool>(
        'applyTelemetryDefault',
      );
      if (applied != true) {
        _logger.warning('Mapbox telemetry could not be turned off.');
      }
    } on PlatformException catch (error, stackTrace) {
      _logger.warning(
        'Mapbox telemetry default failed.',
        error: error,
        stackTrace: stackTrace,
      );
    } on MissingPluginException {
      _logger.warning('Mapbox telemetry channel is not registered.');
    }
  }
}
