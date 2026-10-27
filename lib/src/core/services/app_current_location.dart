import 'package:flutter/services.dart';

/// A foreground position fix. Never stored (doc 05).
typedef AppLocationFix = ({double latitude, double longitude});

/// A fix with how sure the phone is of it and when it was taken: what a
/// check-in needs, since an old or loose fix can't say where someone is.
typedef AppLocationReading = ({
  double latitude,
  double longitude,
  double? accuracyMeters,
  DateTime? takenAt,
});

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

  /// Like [read], with the fix's accuracy and time. The phone may hand back
  /// its last known position when it can't get a fresh one in time; [takenAt]
  /// lets the caller refuse a stale one.
  static Future<AppLocationReading?> readDetailed({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final raw = await _channel
          .invokeMapMethod<String, Object?>('currentLocation')
          .timeout(timeout, onTimeout: () => null);
      final latitude = raw?['latitude'];
      final longitude = raw?['longitude'];
      if (latitude is! num || longitude is! num) return null;
      final accuracy = raw?['accuracy'];
      final time = raw?['time'];
      return (
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        accuracyMeters: accuracy is num ? accuracy.toDouble() : null,
        takenAt: time is num
            ? DateTime.fromMillisecondsSinceEpoch(time.toInt())
            : null,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
