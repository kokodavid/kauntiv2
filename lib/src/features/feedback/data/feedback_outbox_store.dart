import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/feedback_models.dart';

/// A report written while the phone had no connection, kept with its
/// context so it is sent exactly as it was written.
class PendingFeedback {
  const PendingFeedback({required this.draft, required this.context});

  final FeedbackDraft draft;
  final FeedbackContext context;
}

/// Reports waiting for a connection, per account. Files chosen for a
/// report are copied next to the app so the OS clearing its picker cache
/// cannot lose them.
class FeedbackOutboxStore {
  const FeedbackOutboxStore();

  static String _key(String owner) => 'feedback.outbox.$owner';

  Future<List<PendingFeedback>> all(String owner) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(owner));
      if (raw == null) return const [];
      final list = jsonDecode(raw) as List<dynamic>;
      return [for (final item in list) _decode(item as Map<String, dynamic>)];
    } on Object {
      return const [];
    }
  }

  Future<void> add(String owner, PendingFeedback pending) async {
    final kept = await _keepFiles(pending);
    final current = await all(owner);
    final next = [
      for (final item in current)
        if (item.draft.clientId != kept.draft.clientId) item,
      kept,
    ];
    await _write(owner, next);
  }

  Future<void> remove(String owner, String clientId) async {
    final current = await all(owner);
    await _write(owner, [
      for (final item in current)
        if (item.draft.clientId != clientId) item,
    ]);
    try {
      final dir = Directory(await _folder(clientId));
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } on Object {
      // A leftover folder is harmless.
    }
  }

  Future<void> _write(String owner, List<PendingFeedback> items) async {
    final prefs = await SharedPreferences.getInstance();
    if (items.isEmpty) {
      await prefs.remove(_key(owner));
      return;
    }
    await prefs.setString(
      _key(owner),
      jsonEncode([for (final item in items) _encode(item)]),
    );
  }

  Future<String> _folder(String clientId) async {
    final base = await getApplicationDocumentsDirectory();
    return '${base.path}/feedback_outbox/$clientId';
  }

  Future<PendingFeedback> _keepFiles(PendingFeedback pending) async {
    if (pending.draft.attachments.isEmpty) return pending;
    final folder = Directory(await _folder(pending.draft.clientId))
      ..createSync(recursive: true);
    final kept = <FeedbackAttachmentFile>[];
    for (final file in pending.draft.attachments) {
      try {
        final name = file.path.split(Platform.pathSeparator).last;
        final copy = await File(file.path).copy('${folder.path}/$name');
        kept.add(
          FeedbackAttachmentFile(
            path: copy.path,
            mimeType: file.mimeType,
            sizeBytes: file.sizeBytes,
          ),
        );
      } on Object {
        // A file that cannot be kept is dropped; the text still goes.
      }
    }
    final d = pending.draft;
    return PendingFeedback(
      context: pending.context,
      draft: FeedbackDraft(
        clientId: d.clientId,
        category: d.category,
        severity: d.severity,
        title: d.title,
        description: d.description,
        contactOk: d.contactOk,
        attachments: kept,
      ),
    );
  }

  static Map<String, dynamic> _encode(PendingFeedback p) => {
    'clientId': p.draft.clientId,
    'category': p.draft.category.key,
    'severity': p.draft.severity.key,
    'title': p.draft.title,
    'description': p.draft.description,
    'contactOk': p.draft.contactOk,
    'files': [
      for (final f in p.draft.attachments)
        {'path': f.path, 'mime': f.mimeType, 'size': f.sizeBytes},
    ],
    'context': {
      'screen': p.context.screen,
      'appVersion': p.context.appVersion,
      'buildNumber': p.context.buildNumber,
      'flavor': p.context.flavor,
      'platform': p.context.platform,
      'osVersion': p.context.osVersion,
      'deviceModel': p.context.deviceModel,
      'locale': p.context.locale,
      'capturedAt': p.context.capturedAt.toIso8601String(),
    },
  };

  static PendingFeedback _decode(Map<String, dynamic> m) {
    final c = m['context'] as Map<String, dynamic>;
    return PendingFeedback(
      draft: FeedbackDraft(
        clientId: m['clientId'] as String,
        category: FeedbackCategory.fromKey(m['category'] as String?),
        severity: FeedbackSeverity.fromKey(m['severity'] as String?),
        title: m['title'] as String,
        description: m['description'] as String,
        contactOk: m['contactOk'] as bool? ?? false,
        attachments: [
          for (final f
              in (m['files'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>())
            if (File(f['path'] as String).existsSync())
              FeedbackAttachmentFile(
                path: f['path'] as String,
                mimeType: f['mime'] as String,
                sizeBytes: f['size'] as int,
              ),
        ],
      ),
      context: FeedbackContext(
        screen: c['screen'] as String?,
        appVersion: c['appVersion'] as String?,
        buildNumber: c['buildNumber'] as String?,
        flavor: c['flavor'] as String?,
        platform: c['platform'] as String?,
        osVersion: c['osVersion'] as String?,
        deviceModel: c['deviceModel'] as String?,
        locale: c['locale'] as String?,
        capturedAt:
            DateTime.tryParse(c['capturedAt'] as String? ?? '') ??
            DateTime.now(),
      ),
    );
  }
}
