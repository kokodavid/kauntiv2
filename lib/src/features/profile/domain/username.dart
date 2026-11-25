/// What the server says about a username someone is trying (`check_username`).
enum UsernameCheck {
  available,

  /// The account's own current username.
  yours,
  invalid,
  reserved,
  blocked,
  taken;

  static UsernameCheck parse(Object? value) => switch (value) {
    'available' => available,
    'yours' => yours,
    'reserved' => reserved,
    'blocked' => blocked,
    'taken' => taken,
    _ => invalid,
  };

  /// Whether this username can be saved.
  bool get isUsable => this == available || this == yours;

  /// The line shown under the field for a username that can't be used, or
  /// null when it can.
  String? get problemMessage => switch (this) {
    available || yours => null,
    invalid =>
      'Use 3 to 30 letters, numbers, hyphens or underscores, with at least '
          'one letter.',
    reserved => "That name isn't available.",
    blocked => 'Please choose a different name.',
    taken => 'Someone already has that username.',
  };
}

/// `set_username` refused the name (a race with someone else, or a name the
/// server's rules reject).
class UsernameRejectedException implements Exception {
  const UsernameRejectedException(this.reason);

  final UsernameCheck reason;
}

/// The username was changed less than 30 days ago.
class UsernameRateLimitedException implements Exception {
  const UsernameRateLimitedException(this.canChangeAgainAt);

  final DateTime? canChangeAgainAt;
}

/// The words in a username's place: lowercase, trimmed.
String normalizeUsername(String raw) => raw.trim().toLowerCase();
