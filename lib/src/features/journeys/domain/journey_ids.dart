import 'dart:math';

/// Journey ids are random UUIDs made on the phone, so a session has its
/// cloud id from the moment it starts and an upload retry can't create a
/// duplicate.
abstract final class JourneyIds {
  static final _random = Random.secure();

  static String newId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
    final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
    return [
      hex.sublist(0, 4).join(),
      hex.sublist(4, 6).join(),
      hex.sublist(6, 8).join(),
      hex.sublist(8, 10).join(),
      hex.sublist(10).join(),
    ].join('-');
  }
}
