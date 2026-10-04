/// The kinds of moment an owner can choose to show on a public trip. They
/// match the server's allowed list; photos are chosen separately.
enum PublicTripMomentKind {
  countyCrossing('county_crossing', 'County crossing'),
  elevationPeak('elevation_peak', 'Highest point'),
  topSpeed(
    'top_speed',
    'Top speed',
    hint: 'Shows how fast you were going.',
  ),
  longStop(
    'long_stop',
    'Long stop',
    hint: 'Shows where you stopped for a while.',
  ),
  recordingBreak(
    'recording_break',
    'Recording break',
    hint: 'Shows where you paused recording.',
  );

  const PublicTripMomentKind(this.wire, this.label, {this.hint});

  /// The value sent to and returned by the server.
  final String wire;
  final String label;

  /// A light privacy note for kinds that say more about the person than
  /// about the place; null for the others.
  final String? hint;

  bool get isSensitive => hint != null;

  static PublicTripMomentKind? fromWire(String? value) {
    for (final kind in PublicTripMomentKind.values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}
