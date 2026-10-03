import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

import '../domain/journey_fix.dart';
import '../domain/journey_transport_mode.dart';

/// Continuous fixes only for a user-started Journey. Geofencing stays separate.
class DeviceJourneyLocationSource implements JourneyLocationSource {
  DeviceJourneyLocationSource({Location? location})
    : _location = location ?? Location.instance;

  final Location _location;
  bool _started = false;

  @override
  Stream<JourneyFix> get fixes => _location.onLocationChanged
      .map(usableFix)
      .where((fix) => fix != null)
      .map((fix) => fix!);

  @override
  Future<void> ensureAvailable() async {
    if (!await _location.serviceEnabled()) {
      throw const JourneyLocationException(
        JourneyLocationFailure.servicesDisabled,
      );
    }
    final permission = await _location.hasPermission();
    if (permission != PermissionStatus.granted) {
      throw const JourneyLocationException(
        JourneyLocationFailure.permissionDenied,
      );
    }
    if (!await _location.isBackgroundPermissionGranted()) {
      throw const JourneyLocationException(
        JourneyLocationFailure.backgroundPermissionDenied,
      );
    }
  }

  @override
  Future<void> start({JourneyTransportMode? mode}) async {
    if (_started) return;
    await ensureAvailable();
    final sampling = samplingForMode(mode);
    // Clear a service left alive across a process restart before configuring
    // and starting this session's stream.
    await _location.enableBackgroundMode(enable: false);
    if (!await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: sampling.intervalMs,
      backgroundInterval: sampling.backgroundIntervalMs,
      distanceFilter: sampling.distanceMeters,
      pausesLocationUpdatesAutomatically: true,
    )) {
      throw const JourneyLocationException(
        JourneyLocationFailure.settingsUnavailable,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _location.changeNotificationOptions(
        channelName: 'Trip recording',
        title: 'Recording your Trip',
        description:
            'Kaunti47 is saving your route. Open the app to pause or stop.',
        onTapBringToFront: true,
      );
    }
    if (!await _location.enableBackgroundMode(enable: true)) {
      throw const JourneyLocationException(
        JourneyLocationFailure.backgroundModeUnavailable,
      );
    }
    _started = true;
  }

  @override
  Future<void> stop() async {
    // The plugin returns false for a successful disable on Android.
    await _location.enableBackgroundMode(enable: false);
    _started = false;
  }

  static ({int intervalMs, int backgroundIntervalMs, double distanceMeters})
  samplingForMode(JourneyTransportMode? mode) => switch (mode) {
    JourneyTransportMode.drive => (
      intervalMs: 5000,
      backgroundIntervalMs: 8000,
      distanceMeters: 25,
    ),
    JourneyTransportMode.cycle => (
      intervalMs: 7500,
      backgroundIntervalMs: 10000,
      distanceMeters: 12,
    ),
    JourneyTransportMode.walk => (
      intervalMs: 10000,
      backgroundIntervalMs: 15000,
      distanceMeters: 8,
    ),
    null => (
      intervalMs: 5000,
      backgroundIntervalMs: 8000,
      distanceMeters: 10,
    ),
  };

  static JourneyFix? usableFix(LocationData data) {
    final latitude = data.latitude;
    final longitude = data.longitude;
    final accuracy = data.accuracy;
    final milliseconds = data.time;
    if (accuracy == null ||
        milliseconds == null ||
        !milliseconds.isFinite ||
        accuracy > 100 ||
        data.isMock == true) {
      return null;
    }
    final rawAltitude = data.altitude;
    final altitude = (rawAltitude != null && rawAltitude.isFinite)
        ? rawAltitude
        : null;
    final rawSpeed = data.speed;
    final speed = (rawSpeed != null && rawSpeed.isFinite && rawSpeed >= 0)
        ? rawSpeed
        : null;
    try {
      return JourneyFix(
        recordedAt: DateTime.fromMillisecondsSinceEpoch(
          milliseconds.toInt(),
          isUtc: true,
        ),
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracy,
        altitudeMeters: altitude,
        speedMetersPerSecond: speed,
      );
    } on ArgumentError {
      return null;
    }
  }
}
