import 'package:flutter/services.dart';

/// A foreground position fix. Never stored (doc 05).
typedef AppLocationFix = ({double latitude, double longitude});

/// One-shot foreground location read via the app's native
/// `com.giglab.kaunti47/location` channel (ported from v1's
/// `AppCurrentLocationService`): about a 5 s budget natively, no listener
/// left running. Returns null without permission, without a fix, or when
/// the channel isn't there (tests, web).
abstract final class AppCurrentLocation {
  static const _channel = MethodChannel('com.giglab.kaunti47/location');

  static Future<AppLocationFix?> read({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      final raw = await _channel
          .invokeMapMethod<String, Object?>('currentLocation')
          .timeout(timeout, onTimeout: () => null);
      final latitude = raw?['latitude'];
      final longitude = raw?['longitude'];
      if (latitude is! num || longitude is! num) return null;
      return (latitude: latitude.toDouble(), longitude: longitude.toDouble());
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
