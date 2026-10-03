import 'journey_point.dart';
import 'journey_transport_mode.dart';

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

  /// Throws [JourneyLocationException] unless the phone can currently
  /// support a Journey (location services on, permission granted).
  /// Checked up front, before anything else a Start attempt would do
  /// (the live Pro/trial check, creating the local session row), so a
  /// phone that obviously can't record fails immediately instead of
  /// after a network round trip. [start] checks this again itself -
  /// permission can still be revoked or services turned off in the gap
  /// between this call and the actual attach.
  Future<void> ensureAvailable();

  Future<void> start({JourneyTransportMode? mode});
  Future<void> stop();
}

/// Why the phone couldn't start recording a route.
enum JourneyLocationFailure {
  servicesDisabled,
  permissionDenied,
  backgroundPermissionDenied,
  backgroundModeUnavailable,
  settingsUnavailable,

  /// Services were on and permission was granted, but no actual GPS fix
  /// arrived before the wait in [JourneyCapture.attachStarted] timed out -
  /// e.g. a Simulator with no location configured, or a phone indoors with
  /// a poor signal.
  noFixReceived,
}

class JourneyLocationException implements Exception {
  const JourneyLocationException(this.reason);

  final JourneyLocationFailure reason;
}

/// The app has not confirmed that native background capture stopped.
class JourneyTeardownException implements Exception {
  const JourneyTeardownException();
}
