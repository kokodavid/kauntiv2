import 'package:flutter/material.dart';

import '../domain/passport_level.dart';

/// The colours of each stamp level. Bronze, silver and gold are the only
/// colours the Passport adds to the app's own.
extension PassportPalette on PassportLevel {
  /// The ring round the medallion and the stamp fill.
  Color get ring => switch (this) {
    PassportLevel.none => Colors.transparent,
    PassportLevel.passedThrough => const Color(0xFFA1A1AA),
    PassportLevel.explored => const Color(0xFF0A84FF),
    PassportLevel.bronze => const Color(0xFFB0703A),
    PassportLevel.silver => const Color(0xFF8A96A3),
    PassportLevel.gold => const Color(0xFFC99A1A),
  };

  /// The hero band and chip background.
  Color get tint => switch (this) {
    PassportLevel.none => const Color(0xFFF5F5F5),
    PassportLevel.passedThrough => const Color(0xFFF4F4F5),
    PassportLevel.explored => const Color(0xFFE6F3FF),
    PassportLevel.bronze => const Color(0xFFF7EDE3),
    PassportLevel.silver => const Color(0xFFEEF1F4),
    PassportLevel.gold => const Color(0xFFFBF3D9),
  };

  /// Text on [tint].
  Color get text => switch (this) {
    PassportLevel.none => const Color(0xFF71717A),
    PassportLevel.passedThrough => const Color(0xFF52525B),
    PassportLevel.explored => const Color(0xFF0A5FD4),
    PassportLevel.bronze => const Color(0xFF7A4518),
    PassportLevel.silver => const Color(0xFF46515D),
    PassportLevel.gold => const Color(0xFF735400),
  };
}

/// Greys shared by the Passport screens.
abstract final class PassportInk {
  static const primary = Color(0xFF18181B);
  static const secondary = Color(0xFF52525B);
  static const tertiary = Color(0xFF71717A);
  static const disabled = Color(0xFFA1A1AA);
  static const rule = Color(0xFFF4F4F5);
  static const track = Color(0xFFE4E4E7);
  static const dashed = Color(0xFFD4D4D8);
  static const segmentOff = Color(0xFFEEEEF0);
  static const blueDeep = Color(0xFF0A5FD4);
}
