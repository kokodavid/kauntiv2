import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/encoded_photo.dart';
import '../domain/photo_submission.dart';

/// A user's photo submissions for places: sending one and reading back its
/// status. Nothing is public until a person on the team approves it.
abstract interface class PlacePhotosRepository {
  /// Whether the dashboard has switched photo submissions on.
  Future<bool> isEnabled();

  /// The account's username (without the @), or null if it has none.
  Future<String?> myHandle();

  /// Whether the account has chosen its own username (credit lines need it).
  Future<bool> hasChosenUsername();

  /// The signed-in user's submissions, newest first: for one place, or for
  /// every place when [placeId] is null.
  Future<List<PhotoSubmission>> mine({String? placeId});

  /// How many reviewed submissions the user has not looked at yet.
  Future<int> unseenCount();

  /// Marks every reviewed submission as looked at.
  Future<void> markResultsSeen();

  /// Clears a Not published row from the list.
  Future<void> dismiss(String submissionId);

  /// Takes back a photo that is still waiting for review.
  Future<void> withdraw(String submissionId);

  /// A short-lived link to a pending submission's thumbnail.
  Future<String?> thumbnailUrl(String thumbPath);

  /// Upload [photo] and file it for review. Throws [PhotoSubmitFailure]
  /// when the server refuses; anything else is a connection problem.
  Future<void> submit({
    required String placeId,
    required EncodedPhoto photo,
    String? caption,
  });
}

class SupabasePlacePhotosRepository implements PlacePhotosRepository {
  const SupabasePlacePhotosRepository(this.client);

  final SupabaseClient client;

  static const bucket = 'place-photo-submissions';
  static const _timeout = Duration(seconds: 15);
  static const _uploadTimeout = Duration(seconds: 90);

  String get _owner {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in.');
    return id;
  }

  @override
  Future<bool> isEnabled() async {
    final row = await client
        .from('app_feature_flags')
        .select('enabled')
        .eq('feature_key', 'place_photos')
        .maybeSingle()
        .timeout(_timeout);
    return row?['enabled'] == true;
  }

  @override
  Future<String?> myHandle() async {
    final row = await client
        .from('quest_public_profiles')
        .select('handle')
        .eq('user_id', _owner)
        .maybeSingle()
        .timeout(_timeout);
    return row?['handle'] as String?;
  }

  @override
  Future<bool> hasChosenUsername() async {
    final result = await client
        .rpc<dynamic>('has_chosen_username', params: {'p_user_id': _owner})
        .timeout(_timeout);
    return result == true;
  }

  @override
  Future<List<PhotoSubmission>> mine({String? placeId}) async {
    final rows = await client
        .rpc<dynamic>(
          'my_place_photo_submissions',
          params: {'p_place_id': placeId},
        )
        .timeout(_timeout);
    return [
      for (final row in (rows as List).cast<Map<String, dynamic>>())
        PhotoSubmission.fromRow(row),
    ];
  }

  @override
  Future<int> unseenCount() async {
    final result = await client
        .rpc<dynamic>('unseen_place_photo_count')
        .timeout(_timeout);
    return (result as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markResultsSeen() async {
    await client
        .rpc<dynamic>('mark_place_photo_results_seen')
        .timeout(_timeout);
  }

  @override
  Future<void> dismiss(String submissionId) async {
    await client
        .rpc<dynamic>(
          'dismiss_place_photo_submission',
          params: {'p_id': submissionId},
        )
        .timeout(_timeout);
  }

  @override
  Future<void> withdraw(String submissionId) async {
    final rows = await client
        .rpc<dynamic>(
          'withdraw_place_photo_submission',
          params: {'p_id': submissionId},
        )
        .timeout(_timeout);
    final paths = <String>[
      for (final row in (rows as List).cast<Map<String, dynamic>>()) ...[
        if (row['storage_path'] is String) row['storage_path'] as String,
        if (row['thumb_path'] is String) row['thumb_path'] as String,
      ],
    ];
    if (paths.isEmpty) return;
    await _cleanUp(paths);
  }

  @override
  Future<String?> thumbnailUrl(String thumbPath) async {
    try {
      return await client.storage
          .from(bucket)
          .createSignedUrl(thumbPath, 3600)
          .timeout(_timeout);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> submit({
    required String placeId,
    required EncodedPhoto photo,
    String? caption,
  }) async {
    final owner = _owner;
    final id = _newId();
    final fullPath = '$owner/$id.jpg';
    final thumbPath = '$owner/${id}_thumb.jpg';
    const options = FileOptions(contentType: 'image/jpeg');
    final storage = client.storage.from(bucket);
    try {
      await storage
          .uploadBinary(fullPath, photo.full, fileOptions: options)
          .timeout(_uploadTimeout);
      await storage
          .uploadBinary(thumbPath, photo.thumb, fileOptions: options)
          .timeout(_uploadTimeout);
      final trimmed = caption?.trim();
      await client
          .rpc<dynamic>(
            'submit_place_photo',
            params: {
              'p_submission_id': id,
              'p_place_id': placeId,
              'p_caption': trimmed == null || trimmed.isEmpty ? null : trimmed,
              'p_width': photo.width,
              'p_height': photo.height,
              'p_content_hash': photo.hash,
            },
          )
          .timeout(_timeout);
    } on PostgrestException catch (e) {
      await _cleanUp([fullPath, thumbPath]);
      throw PhotoSubmitFailure.fromServer('${e.message} ${e.details ?? ''}');
    } on Object {
      await _cleanUp([fullPath, thumbPath]);
      rethrow;
    }
  }

  Future<void> _cleanUp(List<String> paths) async {
    try {
      await client.storage.from(bucket).remove(paths);
    } on Object {
      // Best effort: a stray private file is harmless and is ignored.
    }
  }

  /// A random (version 4) UUID; the app picks the id so the files and the
  /// database row share it.
  static String _newId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int from, int to) => bytes
        .sublist(from, to)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
