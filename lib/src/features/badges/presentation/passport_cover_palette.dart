import 'package:flutter/material.dart';

/// The cover's own colours: a navy cut from the brand blue's hue, and a
/// gold ink. Used only on the Passport cover; change the navy here to
/// retune the whole cover.
abstract final class PassportCoverPalette {
  static const gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF143B7A), Color(0xFF0A2A5C), Color(0xFF091C42)],
    stops: [0, 0.5, 1],
  );

  /// The deep navy, for text on the white button.
  static const navy = Color(0xFF0A2A5C);

  static const gold = Color(0xFFE3C26B);

  /// Body copy and the name on the navy.
  static const softText = Color(0xFFC9D6EE);
}
