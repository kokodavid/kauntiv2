/// How a Trip was travelled. Chosen once, explicitly, before every
/// recording starts - there is no default - and then used for (1) the
/// icon/label a Trip's card shows and (2) a per-mode sanity limit on how
/// fast a GPS fix could plausibly place the phone, so an implausible jump
/// is dropped rather than corrupting the route.
enum JourneyTransportMode {
  drive,
  walk,
  cycle;

  String get label => switch (this) {
    JourneyTransportMode.drive => 'Drive',
    JourneyTransportMode.walk => 'Walk',
    JourneyTransportMode.cycle => 'Cycle',
  };

  /// A generous top speed for this mode, in m/s - headroom for GPS noise
  /// and momentary spikes, not a hard physical ceiling. A fix implying
  /// anything faster is almost always a jump, not a faster Trip.
  double get maxSpeedMetersPerSecond => switch (this) {
    JourneyTransportMode.drive => 55, // ~198 km/h
    JourneyTransportMode.cycle => 14, // ~50 km/h, a fast downhill
    JourneyTransportMode.walk => 4, // ~14.4 km/h, a brisk jog
  };

  /// The lowercase name stored in the local database and sent to the
  /// server, e.g. `'drive'`.
  String get storageValue => name;

  /// Reverses [storageValue]; null for anything unrecognised (including a
  /// Trip recorded before transport mode existed, which stores NULL).
  static JourneyTransportMode? fromStorage(String? value) {
    for (final mode in JourneyTransportMode.values) {
      if (mode.storageValue == value) return mode;
    }
    return null;
  }
}
