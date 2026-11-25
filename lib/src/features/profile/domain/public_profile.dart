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

/// A username must satisfy this before it is sent to the server: lowercase
/// letters, digits, underscores and hyphens, 3-30 characters, starting with
/// a letter or digit. Mirrors the `quest_public_profiles` check constraint.
/// The server still decides everything else (reserved and blocked words,
/// taken, the 30 day limit).
final _handlePattern = RegExp(r'^[a-z0-9][a-z0-9_-]{2,29}$');

/// Whether a (lowercased) handle would pass the server's format check, for
/// instant feedback before asking the server.
bool isValidHandle(String handle) => _handlePattern.hasMatch(handle);
