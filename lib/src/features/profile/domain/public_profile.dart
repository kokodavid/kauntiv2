/// The account's public identity (`quest_public_profiles`): what Ranks,
/// Friends, and Quests show about this account, and what Edit Profile
/// lets the user change about themselves.
class PublicProfile {
  const PublicProfile({
    required this.displayName,
    required this.handle,
    this.avatarUrl,
  });

  final String displayName;
  final String handle;
  final String? avatarUrl;

  PublicProfile copyWith({
    String? displayName,
    String? handle,
    Object? avatarUrl = _unset,
  }) => PublicProfile(
    displayName: displayName ?? this.displayName,
    handle: handle ?? this.handle,
    avatarUrl: identical(avatarUrl, _unset)
        ? this.avatarUrl
        : avatarUrl as String?,
  );

  static const _unset = Object();
}

/// `handle` must satisfy this before it's sent to the server: lowercase
/// letters, digits, underscores and hyphens, 3-30 characters, starting
/// with a letter or digit. Mirrors the `quest_public_profiles` check
/// constraint exactly (see `add_social_quests.sql` /
/// `add_user_profile_edit_rpc.sql`) -- note this does NOT allow a dot,
/// even though Edit Profile's helper copy says "letters, numbers, dots
/// and underscores"; that copy is wrong against the live constraint and
/// is corrected here rather than silently matched, since loosening the
/// constraint to allow dots is a schema change that needs its own
/// decision (handle uniqueness collation, existing seed handles, etc.).
final _handlePattern = RegExp(r'^[a-z0-9][a-z0-9_-]{2,29}$');

/// Whether a (lowercased) handle would pass the server's own check
/// constraint. Used for instant Edit Profile feedback before the
/// network round trip that catches a taken handle.
bool isValidHandle(String handle) => _handlePattern.hasMatch(handle);

/// Raised when `handle` is already taken (the unique-violation path on
/// `quest_public_profiles.handle`).
class HandleAlreadyTakenException implements Exception {
  const HandleAlreadyTakenException(this.handle);

  final String handle;
}
