import 'dart:math';

/// What a report is about. `key` is the value the database stores.
enum FeedbackCategory {
  bug('bug', 'Bug', 'Something is broken or wrong'),
  featureIdea('feature_idea', 'Feature idea', 'Something that should exist'),
  contentIssue('content_issue', 'Content issue', 'A place, county or fact'),
  performance('performance', 'Performance', 'Slow, laggy or draining'),
  usability('usability', 'Usability', 'Confusing or hard to use');

  const FeedbackCategory(this.key, this.label, this.hint);

  final String key;
  final String label;
  final String hint;

  static FeedbackCategory fromKey(String? key) => FeedbackCategory.values
      .firstWhere((c) => c.key == key, orElse: () => FeedbackCategory.bug);
}

/// How much the problem gets in the way.
enum FeedbackSeverity {
  blocking('blocking', 'Blocking', 'I cannot continue'),
  major('major', 'Major', 'It hurts, but I can work around it'),
  minor('minor', 'Minor', 'A small annoyance');

  const FeedbackSeverity(this.key, this.label, this.hint);

  final String key;
  final String label;
  final String hint;

  static FeedbackSeverity fromKey(String? key) => FeedbackSeverity.values
      .firstWhere((s) => s.key == key, orElse: () => FeedbackSeverity.minor);
}

/// Where a report is in the review workflow.
enum FeedbackStatus {
  received('received', 'Received'),
  triaged('triaged', 'Triaged'),
  investigating('investigating', 'Investigating'),
  planned('planned', 'Planned'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed'),
  rejected('rejected', 'Not planned'),
  duplicate('duplicate', 'Duplicate');

  const FeedbackStatus(this.key, this.label);

  final String key;
  final String label;

  /// Still waiting on the team.
  bool get isOpen =>
      this == received ||
      this == triaged ||
      this == investigating ||
      this == planned;

  static FeedbackStatus fromKey(String? key) => FeedbackStatus.values
      .firstWhere((s) => s.key == key, orElse: () => FeedbackStatus.received);
}

/// A screenshot or recording chosen for a report, still on this phone.
class FeedbackAttachmentFile {
  const FeedbackAttachmentFile({
    required this.path,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String path;
  final String mimeType;
  final int sizeBytes;

  bool get isVideo => mimeType.startsWith('video/');

  /// The most files one report can carry (the database enforces it too).
  static const maxPerReport = 3;

  /// Bucket limit: 50 MB per file.
  static const maxBytes = 50 * 1024 * 1024;

  static const imageTypes = {'image/jpeg', 'image/png', 'image/webp'};
  static const videoTypes = {'video/mp4', 'video/quicktime'};

  /// The type a file name implies, or null when it is not allowed.
  static String? mimeForPath(String path) {
    final dot = path.lastIndexOf('.');
    final extension = dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      _ => null,
    };
  }
}

/// What the tester typed and chose.
class FeedbackDraft {
  const FeedbackDraft({
    required this.clientId,
    required this.category,
    required this.severity,
    required this.title,
    required this.description,
    this.contactOk = false,
    this.attachments = const [],
  });

  /// One per attempt, so a retry after a dropped connection never files
  /// the same report twice.
  final String clientId;
  final FeedbackCategory category;
  final FeedbackSeverity severity;
  final String title;
  final String description;
  final bool contactOk;
  final List<FeedbackAttachmentFile> attachments;

  static const titleMin = 3;
  static const titleMax = 120;
  static const descriptionMin = 10;
  static const descriptionMax = 4000;

  static bool titleOk(String text) {
    final length = text.trim().length;
    return length >= titleMin && length <= titleMax;
  }

  static bool descriptionOk(String text) {
    final length = text.trim().length;
    return length >= descriptionMin && length <= descriptionMax;
  }

  /// A random v4 id for [clientId].
  static String newClientId([Random? random]) {
    final r = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int from, int to) => [
      for (var i = from; i < to; i++)
        bytes[i].toRadixString(16).padLeft(2, '0'),
    ].join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}

/// What the app captures on its own, so nobody has to describe their phone.
class FeedbackContext {
  const FeedbackContext({
    this.screen,
    this.appVersion,
    this.buildNumber,
    this.flavor,
    this.platform,
    this.osVersion,
    this.deviceModel,
    this.locale,
    required this.capturedAt,
  });

  final String? screen;
  final String? appVersion;
  final String? buildNumber;
  final String? flavor;
  final String? platform;
  final String? osVersion;
  final String? deviceModel;
  final String? locale;
  final DateTime capturedAt;
}

/// The confirmation a tester gets after a report is filed.
class FeedbackReceipt {
  const FeedbackReceipt({required this.id, required this.reference});

  final String id;

  /// "FB-0042".
  final String reference;
}

/// What happened to a submission.
class FeedbackSubmission {
  const FeedbackSubmission.sent(this.receipt, {this.filesNotSent = 0})
    : queued = false;

  const FeedbackSubmission.queued()
    : receipt = null,
      filesNotSent = 0,
      queued = true;

  /// Null when the report is waiting for a connection.
  final FeedbackReceipt? receipt;
  final bool queued;

  /// Attachments that did not upload (the report itself was filed).
  final int filesNotSent;
}

/// One of the signed-in tester's own reports.
class FeedbackReport {
  const FeedbackReport({
    required this.id,
    required this.reference,
    required this.category,
    required this.severity,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.testerResponse,
    this.respondedAt,
  });

  final String id;
  final String reference;
  final FeedbackCategory category;
  final FeedbackSeverity severity;
  final String title;
  final FeedbackStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The one line of text staff leave for the tester.
  final String? testerResponse;
  final DateTime? respondedAt;
}

/// A report that could not be filed, with a sentence the tester can read.
class FeedbackFailure implements Exception {
  const FeedbackFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
