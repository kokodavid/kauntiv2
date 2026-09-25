import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

import '../domain/journey_fix.dart';

enum JourneyLocationFailure {
  servicesDisabled,
  permissionDenied,
  backgroundPermissionDenied,
  backgroundModeUnavailable,
  settingsUnavailable,
}

class JourneyLocationException implements Exception {
  const JourneyLocationException(this.reason);

  final JourneyLocationFailure reason;
}

/// Continuous fixes only for a user-started Journey. Geofencing stays separate.
class DeviceJourneyLocationSource implements JourneyLocationSource {
  DeviceJourneyLocationSource({Location? location})
    : _location = location ?? Location.instance;

  final Location _location;
  bool _started = false;

  @override
  Stream<JourneyFix> get fixes async* {
    await for (final data in _location.onLocationChanged) {
      final fix = usableFix(data);
      if (fix != null) yield fix;
    }
  }

  @override
  Future<void> start() async {
    if (_started) return;
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
    if (!await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 5000,
      distanceFilter: 10,
      pausesLocationUpdatesAutomatically: false,
    )) {
      throw const JourneyLocationException(
        JourneyLocationFailure.settingsUnavailable,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _location.changeNotificationOptions(
        channelName: 'Journey recording',
        title: 'Recording your Journey',
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
    if (!_started) return;
    _started = false;
    await _location.enableBackgroundMode(enable: false);
  }

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
    try {
      return JourneyFix(
        recordedAt: DateTime.fromMillisecondsSinceEpoch(
          milliseconds.toInt(),
          isUtc: true,
        ),
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracy,
      );
    } on ArgumentError {
      return null;
    }
  }
}
