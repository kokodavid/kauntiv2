import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/fail_fast.dart';
import '../domain/feedback_models.dart';

/// True when [error] means the server could not be reached, as opposed to
/// the server refusing the report. Unreachable reports are kept and sent
/// later; refused ones are shown to the tester.
bool feedbackIsUnreachable(Object error) =>
    error is OfflineException ||
    error is SocketException ||
    error is TimeoutException ||
    error is http.ClientException ||
    error is AuthRetryableFetchException;

/// True when the server read the report and refused it (seat revoked, text
/// too short): retrying will not help.
bool feedbackIsRefused(Object error) => error is PostgrestException;

/// A sentence for the tester when a report could not be filed.
String feedbackFailureMessage(Object error) {
  if (error is PostgrestException) {
    return switch (error.code) {
      '42501' => 'Feedback is open to beta testers only.',
      '54000' => error.message,
      '22023' => error.message,
      _ => "Couldn't send your feedback. Try again.",
    };
  }
  return "Couldn't send your feedback. Try again.";
}

/// Beta feedback: who may send it, filing a report, and reading back the
/// tester's own reports. Reports go in through one database function that
/// re-checks the seat; there is no direct table write.
abstract interface class FeedbackRepository {
  /// Whether this account held a tester seat the last time it was checked
  /// on this phone, or null when it has never been checked. Never touches
  /// the network.
  Future<bool?> cachedHasTesterSeat();

  /// Whether the signed-in account holds an active tester seat (also
  /// remembered on this phone so the Profile entry works offline).
  Future<bool> hasTesterSeat();

  /// File [draft]. The report is filed first and its files uploaded after,
  /// so a failed upload never loses the text.
  Future<FeedbackSubmission> submit(
    FeedbackDraft draft,
    FeedbackContext context,
  );

  /// The signed-in tester's reports, newest first.
  Future<List<FeedbackReport>> mine();
}

class SupabaseFeedbackRepository implements FeedbackRepository {
  const SupabaseFeedbackRepository(this.client);

  final SupabaseClient client;

  static const bucket = 'feedback-media';
  static const _timeout = Duration(seconds: 15);
  static const _uploadTimeout = Duration(seconds: 90);

  String? get _owner => client.auth.currentUser?.id;

  static String _seatKey(String owner) => 'feedback.has_seat.$owner';

  @override
  Future<bool?> cachedHasTesterSeat() async {
    final owner = _owner;
    if (owner == null) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_seatKey(owner));
    } on Object {
      return null;
    }
  }

  @override
  Future<bool> hasTesterSeat() async {
    final owner = _owner;
    if (owner == null) return false;
    final seat = await client
        .rpc<bool>('has_tester_seat')
        .timeout(_timeout);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seatKey(owner), seat);
    } on Object {
      // The copy on this phone is only a speed-up.
    }
    return seat;
  }

  @override
  Future<FeedbackSubmission> submit(
    FeedbackDraft draft,
    FeedbackContext context,
  ) async {
    final owner = _owner;
    if (owner == null) throw StateError('Sign in to send feedback.');
    final rows = await client
        .rpc<List<dynamic>>(
          'submit_feedback',
          params: {
            'p_category': draft.category.key,
            'p_severity': draft.severity.key,
            'p_title': draft.title.trim(),
            'p_description': draft.description.trim(),
            'p_screen': context.screen,
            'p_app_version': context.appVersion,
            'p_build_number': context.buildNumber,
            'p_flavor': context.flavor,
            'p_platform': context.platform,
            'p_os_version': context.osVersion,
            'p_device_model': context.deviceModel,
            'p_locale': context.locale,
            'p_contact_ok': draft.contactOk,
            'p_client_id': draft.clientId,
          },
        )
        .timeout(_timeout);
    final row = rows.first as Map<dynamic, dynamic>;
    final receipt = FeedbackReceipt(
      id: row['id'] as String,
      reference: row['reference'] as String,
    );
    final failed = await _upload(owner, receipt.id, draft.attachments);
    return FeedbackSubmission.sent(receipt, filesNotSent: failed);
  }

  Future<int> _upload(
    String owner,
    String reportId,
    List<FeedbackAttachmentFile> files,
  ) async {
    var failed = 0;
    for (final file in files) {
      try {
        final extension = file.path.split('.').last.toLowerCase();
        final path =
            '$owner/$reportId/${FeedbackDraft.newClientId()}.$extension';
        await client.storage
            .from(bucket)
            .upload(
              path,
              File(file.path),
              fileOptions: FileOptions(contentType: file.mimeType),
            )
            .timeout(_uploadTimeout);
        await client
            .rpc<dynamic>(
              'add_feedback_attachment',
              params: {
                'p_report_id': reportId,
                'p_storage_path': path,
                'p_mime_type': file.mimeType,
                'p_size_bytes': file.sizeBytes,
              },
            )
            .timeout(_timeout);
      } on Object {
        failed++;
      }
    }
    return failed;
  }

  @override
  Future<List<FeedbackReport>> mine() async {
    final owner = _owner;
    if (owner == null) return const [];
    final rows = await client
        .from('feedback_reports')
        .select(
          'id, reference, category, severity, title, status, '
          'tester_response, responded_at, created_at, updated_at',
        )
        .eq('user_id', owner)
        .order('created_at', ascending: false)
        .limit(100)
        .timeout(_timeout);
    return [
      for (final raw in rows)
        FeedbackReport(
          id: raw['id'] as String,
          reference: (raw['reference'] as String?) ?? '',
          category: FeedbackCategory.fromKey(raw['category'] as String?),
          severity: FeedbackSeverity.fromKey(raw['severity'] as String?),
          title: raw['title'] as String,
          status: FeedbackStatus.fromKey(raw['status'] as String?),
          testerResponse: raw['tester_response'] as String?,
          respondedAt: _date(raw['responded_at']),
          createdAt: _date(raw['created_at']) ?? DateTime.now(),
          updatedAt: _date(raw['updated_at']) ?? DateTime.now(),
        ),
    ];
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
