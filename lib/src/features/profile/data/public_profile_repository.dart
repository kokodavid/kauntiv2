import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/public_profile.dart';

abstract interface class PublicProfileRepository {
  Future<PublicProfile?> fetch();
  Future<PublicProfile> update({String? displayName, String? handle});
  Future<String> uploadAvatar(Uint8List bytes, {required String extension});
}

/// `quest_public_profiles` is already owner-writable by RLS (see
/// `add_social_quests.sql`'s "Users can update their own quest public
/// profile" policy), so Edit Profile is a plain client update -- no RPC
/// needed. The server-side check constraint on `handle` is the real
/// validation; [isValidHandle] just mirrors it for instant UI feedback.
class SupabasePublicProfileRepository implements PublicProfileRepository {
  const SupabasePublicProfileRepository(this.client);

  final SupabaseClient client;

  static const _timeout = Duration(seconds: 8);

  String _owner() {
    final owner = client.auth.currentUser?.id;
    if (owner == null) {
      throw StateError('Public profile access requires a session');
    }
    return owner;
  }

  @override
  Future<PublicProfile?> fetch() async {
    final owner = _owner();
    final row = await client
        .from('quest_public_profiles')
        .select('display_name, handle, avatar_url')
        .eq('user_id', owner)
        .maybeSingle()
        .timeout(_timeout);
    if (row == null) return null;
    return PublicProfile(
      displayName: row['display_name'] as String,
      handle: row['handle'] as String,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  @override
  Future<PublicProfile> update({String? displayName, String? handle}) async {
    final owner = _owner();
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'display_name': ?displayName,
      'handle': ?handle,
    };
    try {
      final row = await client
          .from('quest_public_profiles')
          .update(payload)
          .eq('user_id', owner)
          .select('display_name, handle, avatar_url')
          .single()
          .timeout(_timeout);
      return PublicProfile(
        displayName: row['display_name'] as String,
        handle: row['handle'] as String,
        avatarUrl: row['avatar_url'] as String?,
      );
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw HandleAlreadyTakenException(handle ?? '');
      }
      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar(
    Uint8List bytes, {
    required String extension,
  }) async {
    final owner = _owner();
    final path = '$owner/avatar.$extension';
    await client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$extension',
          ),
        )
        .timeout(const Duration(seconds: 30));
    // Cache-bust: the path never changes, so a plain public URL would be
    // served stale from the CDN/device image cache after re-uploading.
    final publicUrl = client.storage.from('avatars').getPublicUrl(path);
    final avatarUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    await client
        .from('quest_public_profiles')
        .update({
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', owner)
        .timeout(_timeout);
    return avatarUrl;
  }
}
