import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/public_profile.dart';

abstract interface class PublicProfileRepository {
  Future<PublicProfile?> fetch();
  Future<PublicProfile> update({String? displayName});
  Future<String> uploadAvatar(Uint8List bytes, {required String extension});
}

/// The display name and avatar on `quest_public_profiles` are owner-writable
/// by RLS, so Edit Profile saves them with a plain client update. The
/// username (`handle`) is not: it changes only through the
/// `set_username` RPC (see `UsernameRepository`), which enforces the rules
/// and the 30 day limit.
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
  Future<PublicProfile> update({String? displayName}) async {
    final owner = _owner();
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'display_name': ?displayName,
    };
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
