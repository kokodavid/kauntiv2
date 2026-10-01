import 'journey_point.dart';

class JourneyFix {
  JourneyFix({
    required this.recordedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    this.altitudeMeters,
    this.speedMetersPerSecond,
  }) {
    JourneyPoint(
      recordedAt: recordedAt,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      segmentNumber: 0,
      altitudeMeters: altitudeMeters,
      speedMetersPerSecond: speedMetersPerSecond,
    );
  }

  final DateTime recordedAt;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double? altitudeMeters;
  final double? speedMetersPerSecond;

  JourneyPoint inSegment(int segmentNumber) => JourneyPoint(
    recordedAt: recordedAt,
    latitude: latitude,
    longitude: longitude,
    accuracyMeters: accuracyMeters,
    segmentNumber: segmentNumber,
    altitudeMeters: altitudeMeters,
    speedMetersPerSecond: speedMetersPerSecond,
  );
}

abstract interface class JourneyLocationSource {
  Stream<JourneyFix> get fixes;

  Future<void> start();
  Future<void> stop();
}

/// Why the phone couldn't start recording a route.
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

/// The app has not confirmed that native background capture stopped.
class JourneyTeardownException implements Exception {
  const JourneyTeardownException();
}
