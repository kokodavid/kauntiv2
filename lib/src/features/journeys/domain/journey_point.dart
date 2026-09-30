class JourneyPoint {
  JourneyPoint({
    required this.recordedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.segmentNumber,
    this.altitudeMeters,
    this.speedMetersPerSecond,
  }) {
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180 ||
        !accuracyMeters.isFinite ||
        accuracyMeters < 0 ||
        segmentNumber < 0 ||
        (altitudeMeters != null && !altitudeMeters!.isFinite) ||
        (speedMetersPerSecond != null &&
            (!speedMetersPerSecond!.isFinite || speedMetersPerSecond! < 0))) {
      throw ArgumentError('Invalid Journey point.');
    }
  }

  final DateTime recordedAt;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final int segmentNumber;

  /// Height above sea level, when the fix reported one.
  final double? altitudeMeters;

  /// The device's instantaneous speed at this fix, when it reported one.
  final double? speedMetersPerSecond;
}
