class JourneyPoint {
  JourneyPoint({
    required this.recordedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.segmentNumber,
  }) {
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180 ||
        !accuracyMeters.isFinite ||
        accuracyMeters < 0 ||
        segmentNumber < 0) {
      throw ArgumentError('Invalid Journey point.');
    }
  }

  final DateTime recordedAt;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final int segmentNumber;
}
