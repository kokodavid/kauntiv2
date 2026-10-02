/// A photo taken while actively recording a Trip, still only on this
/// phone (captured, maybe not yet uploaded).
class JourneyMediaCapture {
  const JourneyMediaCapture({
    required this.id,
    required this.journeyId,
    required this.localPath,
    required this.capturedAt,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String journeyId;

  /// Where the file lives in the app's own persistent storage (copied
  /// there from image_picker's cache so it survives until uploaded).
  final String localPath;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
}

/// A photo already uploaded for a Trip, ready to show in Replay.
class JourneyMediaItem {
  const JourneyMediaItem({
    required this.id,
    required this.url,
    required this.capturedAt,
    this.latitude,
    this.longitude,
  });

  final String id;

  /// A short-lived signed URL (the bucket is private): fetch it again
  /// rather than caching it past the session that loaded it.
  final String url;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
}
