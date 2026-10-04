import 'public_trip_json.dart';
import 'public_trip_moment_kind.dart';

enum PublicTripStatus {
  prepared,
  submitted,
  approved,
  rejected,
  revoked,
  superseded;

  static PublicTripStatus fromWire(String? value) {
    for (final status in PublicTripStatus.values) {
      if (status.name == value) return status;
    }
    return PublicTripStatus.revoked;
  }
}

/// Where a trip stands from its owner's side, for the badge and actions.
enum PublicTripPhase {
  /// Never made public, or withdrawn: the owner can start again.
  none,

  /// Waiting for a moderator.
  awaitingReview,

  /// Live. [PublicTripOwnerView.hasPendingChange] says whether an edit is
  /// also waiting for review.
  isPublic,

  /// A moderator asked for changes.
  needsChanges,

  /// A moderator hid it; the owner cannot republish until it is allowed.
  hidden,
}

class PublicTripCounty {
  const PublicTripCounty({required this.code, required this.name});

  final int code;
  final String name;
}

class PublicTripPoint {
  const PublicTripPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class PublicTripMoment {
  const PublicTripMoment({
    required this.kind,
    required this.latitude,
    required this.longitude,
  });

  final PublicTripMomentKind kind;
  final double latitude;
  final double longitude;
}

/// What the server returns to the owner about their trip's latest revision:
/// the sanitized preview, its review status, and what was left out.
class PublicTripOwnerView {
  const PublicTripOwnerView({
    required this.id,
    required this.status,
    this.revision = 0,
    this.title = '',
    this.tripDate,
    this.transportMode,
    this.distanceMeters = 0,
    this.counties = const [],
    this.routeLines = const [],
    this.moments = const [],
    this.photoCount = 0,
    this.photosPending = 0,
    this.photosFailed = 0,
    this.contentHash = '',
    this.expiresAt,
    this.reviewReason,
    this.startTrimMeters = 500,
    this.endTrimMeters = 500,
    this.excludedMomentCount = 0,
    this.excludedPhotoCount = 0,
    this.activeRevision,
    this.hidden = false,
  });

  final String id;
  final PublicTripStatus status;
  final int revision;
  final String title;
  final DateTime? tripDate;
  final String? transportMode;
  final double distanceMeters;
  final List<PublicTripCounty> counties;

  /// The public route as separate lines (a recording break splits it).
  final List<List<PublicTripPoint>> routeLines;
  final List<PublicTripMoment> moments;
  final int photoCount;
  final int photosPending;
  final int photosFailed;
  final String contentHash;
  final DateTime? expiresAt;

  /// The moderator's reason, for a rejected revision.
  final String? reviewReason;
  final int startTrimMeters;
  final int endTrimMeters;
  final int excludedMomentCount;
  final int excludedPhotoCount;

  /// The revision currently live, if any.
  final int? activeRevision;
  final bool hidden;

  bool get hasPreview => routeLines.isNotEmpty;
  bool get photosReady => photosPending == 0;

  bool get isExpired {
    final at = expiresAt;
    return at != null && !at.isAfter(DateTime.now());
  }

  bool get isLive => activeRevision != null && !hidden;

  /// A newer revision is waiting for review while an older one is live.
  bool get hasPendingChange =>
      isLive && status == PublicTripStatus.submitted && revision != activeRevision;

  PublicTripPhase get phase {
    if (hidden) return PublicTripPhase.hidden;
    if (isLive) return PublicTripPhase.isPublic;
    return switch (status) {
      PublicTripStatus.submitted => PublicTripPhase.awaitingReview,
      PublicTripStatus.rejected => PublicTripPhase.needsChanges,
      _ => PublicTripPhase.none,
    };
  }

  factory PublicTripOwnerView.fromJson(Map<String, dynamic> json) {
    final excluded = json['excluded'] as Map<String, dynamic>? ?? const {};
    return PublicTripOwnerView(
      id: json['id'] as String,
      status: PublicTripStatus.fromWire(json['status'] as String?),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      tripDate: DateTime.tryParse(json['trip_date'] as String? ?? ''),
      transportMode: json['transport_mode'] as String?,
      distanceMeters: (json['distance_m'] as num?)?.toDouble() ?? 0,
      counties: publicTripCounties(json['counties']),
      routeLines: publicTripRouteLines(json['route']),
      moments: publicTripMoments(json['moments']),
      photoCount: (json['photos'] as List<dynamic>? ?? const []).length,
      photosPending: (json['photos_pending'] as num?)?.toInt() ?? 0,
      photosFailed: (json['photos_failed'] as num?)?.toInt() ?? 0,
      contentHash: json['content_hash'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      reviewReason: json['review_reason'] as String?,
      startTrimMeters: (json['start_trim_m'] as num?)?.toInt() ?? 500,
      endTrimMeters: (json['end_trim_m'] as num?)?.toInt() ?? 500,
      excludedMomentCount:
          (excluded['moments'] as List<dynamic>? ?? const []).length,
      excludedPhotoCount:
          (excluded['photo_ids'] as List<dynamic>? ?? const []).length,
      activeRevision: (json['active_revision'] as num?)?.toInt(),
      hidden: json['hidden'] as bool? ?? false,
    );
  }
}
