enum PhotoSubmissionStatus {
  pending,
  approved,
  rejected;

  static PhotoSubmissionStatus of(String? value) => switch (value) {
    'approved' => approved,
    'rejected' => rejected,
    _ => pending,
  };
}

/// One of the signed-in user's own photo submissions.
class PhotoSubmission {
  const PhotoSubmission({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.status,
    required this.createdAt,
    this.countyName,
    this.caption,
    this.rejectReason,
    this.thumbPath,
    this.publishedThumbnailUrl,
    this.shown = true,
    this.unseen = false,
    this.reviewedAt,
  });

  factory PhotoSubmission.fromRow(Map<String, dynamic> row) => PhotoSubmission(
    id: row['id'] as String,
    placeId: row['place_id'] as String,
    placeName: (row['place_name'] as String?) ?? '',
    countyName: row['county_name'] as String?,
    status: PhotoSubmissionStatus.of(row['status'] as String?),
    createdAt: DateTime.parse(row['created_at'] as String),
    caption: row['caption'] as String?,
    rejectReason: row['reject_reason'] as String?,
    thumbPath: row['thumb_path'] as String?,
    publishedThumbnailUrl: row['published_thumbnail_url'] as String?,
    shown: row['shown'] != false,
    unseen: row['unseen'] == true,
    reviewedAt: row['reviewed_at'] == null
        ? null
        : DateTime.parse(row['reviewed_at'] as String),
  );

  final String id;
  final String placeId;
  final String placeName;
  final String? countyName;
  final PhotoSubmissionStatus status;
  final DateTime createdAt;
  final String? caption;
  final String? rejectReason;

  /// Private-bucket path of the thumbnail; only set while pending.
  final String? thumbPath;

  /// Public thumbnail; only set once approved.
  final String? publishedThumbnailUrl;

  /// False for an approved photo that was later taken down.
  final bool shown;

  /// Reviewed, and the user has not looked at the result yet.
  final bool unseen;
  final DateTime? reviewedAt;

  bool get isPending => status == PhotoSubmissionStatus.pending;
  bool get isRejected => status == PhotoSubmissionStatus.rejected;
  bool get isTakenDown => status == PhotoSubmissionStatus.approved && !shown;
}

/// Why a submission was refused, with a sentence for the person.
class PhotoSubmitFailure implements Exception {
  const PhotoSubmitFailure(this.code, this.message);

  final String code;
  final String message;

  static const needsUsername = 'username_required';

  /// The problem is this photo: the person should choose another.
  bool get needsAnotherPhoto =>
      code == 'image_too_small' || code == 'duplicate_photo';

  /// What the button under the message says.
  String get actionLabel => needsAnotherPhoto
      ? 'Choose another photo'
      : code == needsUsername
      ? 'Choose a username'
      : 'OK';

  /// Maps the server's exception text (see `submit_place_photo`).
  static PhotoSubmitFailure fromServer(String text) {
    final code = const [
      'feature_off',
      'username_required',
      'place_unavailable',
      'upload_missing',
      'image_too_small',
      'too_many_pending',
      'place_limit',
      'daily_limit',
      'duplicate_photo',
    ].firstWhere(text.contains, orElse: () => 'unknown');
    return PhotoSubmitFailure(code, messageFor(code));
  }

  static String messageFor(String code) => _messages[code] ?? _fallback;

  static const _fallback = "Couldn't send your photo. Try again.";

  static const _messages = {
    'feature_off': 'Adding photos is paused for now. Please try again later.',
    'username_required':
        'Choose a username first. Your photo is credited to it.',
    'place_unavailable': "This place isn't open for photos yet.",
    'upload_missing': "The upload didn't finish. Try again.",
    'image_too_small':
        'This photo is too small. Choose one that is at least 800 px on the '
        'long side.',
    'too_many_pending':
        'You have 5 photos waiting for review. You can send more once we '
        'have checked some.',
    'place_limit':
        'You have 2 photos of this place waiting for review. You can send '
        'another once one is checked.',
    'daily_limit':
        "You've sent 10 photos in the last 24 hours. You can send more later.",
    'duplicate_photo': "You've already sent this photo.",
  };

  @override
  String toString() => 'PhotoSubmitFailure($code)';
}
