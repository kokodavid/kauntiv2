import 'journey_point.dart';

class JourneyFix {
  JourneyFix({
    required this.recordedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  }) {
    JourneyPoint(
      recordedAt: recordedAt,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      segmentNumber: 0,
    );
  }

  final DateTime recordedAt;
  final double latitude;
  final double longitude;
  final double accuracyMeters;

  JourneyPoint inSegment(int segmentNumber) => JourneyPoint(
    recordedAt: recordedAt,
    latitude: latitude,
    longitude: longitude,
    accuracyMeters: accuracyMeters,
    segmentNumber: segmentNumber,
  );
}

abstract interface class JourneyLocationSource {
  Stream<JourneyFix> get fixes;

  Future<void> start();
  Future<void> stop();
}
