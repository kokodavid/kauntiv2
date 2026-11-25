import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

/// One low-power fix for county detection. Used only to decide the county
/// and never stored (doc 05).
typedef CountyTrackingFix = ({
  double latitude,
  double longitude,
  double accuracyMeters,
  DateTime at,
});

/// Background location for "Accurate county times". Coarse (cell and
/// Wi-Fi), a fix only after moving about a kilometre, a few minutes apart:
/// enough to see a county change without the cost of GPS.
abstract interface class CountyTrackingSource {
  /// Location is on and allowed all the time (the same as geofences need).
  Future<bool> canRun();

  /// Starts background updates; null when they can't run.
  Future<Stream<CountyTrackingFix>?> start();

  /// Puts the low-power settings back (Home's motion sensing raises them
  /// while it is open, and the plugin keeps one set of settings).
  Future<void> applySettings();

  Future<void> stop();
}

class DeviceCountyTrackingSource implements CountyTrackingSource {
  DeviceCountyTrackingSource({Location? location})
    : _location = location ?? Location.instance;

  final Location _location;

  /// Coarser than this can't tell neighbouring counties apart.
  static const maxAccuracyMeters = 1500.0;
  static const _intervalMs = 180000;
  static const _distanceMeters = 1000.0;

  @override
  Future<bool> canRun() async {
    try {
      if (!await _location.serviceEnabled()) return false;
      if (await _location.hasPermission() != PermissionStatus.granted) {
        return false;
      }
      return await _location.isBackgroundPermissionGranted();
    } on Object {
      return false;
    }
  }

  @override
  Future<void> applySettings() async {
    await _location.changeSettings(
      accuracy: LocationAccuracy.low,
      interval: _intervalMs,
      backgroundInterval: _intervalMs,
      distanceFilter: _distanceMeters,
      pausesLocationUpdatesAutomatically: false,
    );
  }

  @override
  Future<Stream<CountyTrackingFix>?> start() async {
    if (!await canRun()) return null;
    await applySettings();
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _location.changeNotificationOptions(
        channelName: 'County detection',
        title: 'Tracking county crossings',
        description: 'Accurate county times is on. Turn it off in Settings.',
        onTapBringToFront: true,
      );
    }
    if (!await _location.enableBackgroundMode(enable: true)) return null;
    return _location.onLocationChanged
        .map(usableFix)
        .where((fix) => fix != null)
        .map((fix) => fix!);
  }

  @override
  Future<void> stop() async {
    // The plugin can report false for a successful disable on Android.
    await _location.enableBackgroundMode(enable: false);
  }

  /// A fix good enough to place in a county, or null.
  static CountyTrackingFix? usableFix(LocationData data) {
    final latitude = data.latitude;
    final longitude = data.longitude;
    final accuracy = data.accuracy;
    final milliseconds = data.time;
    if (latitude == null ||
        longitude == null ||
        accuracy == null ||
        milliseconds == null ||
        !milliseconds.isFinite ||
        accuracy > maxAccuracyMeters ||
        data.isMock == true) {
      return null;
    }
    return (
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracy,
      at: DateTime.fromMillisecondsSinceEpoch(
        milliseconds.toInt(),
        isUtc: true,
      ),
    );
  }
}
