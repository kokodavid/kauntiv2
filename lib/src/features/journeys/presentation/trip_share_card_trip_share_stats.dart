part of 'trip_share_card.dart';

/// Formatting specific to this card: more decimal precision than the
/// compact history-card facts pill uses, since these numbers are the
/// whole point of a share image. Returns (value, unit) separately so the
/// layout can style them differently, rather than one combined string.
abstract final class _TripShareStats {
  /// Always rendered in km, even for a short Trip - a fixed unit keeps
  /// the stat grid's layout predictable. 1 decimal under 100 km, none
  /// at or above it (matches the reference's own examples: "42.3 km",
  /// "612 km").
  ///
  /// Null, not a "—" placeholder, when the underlying value is missing -
  /// [_StatGrid] drops a null cell from the grid entirely instead of
  /// showing an empty dash for a stat the Trip never recorded.
  static (String, String)? distance(double? meters) {
    if (meters == null) return null;
    final km = meters / 1000;
    final value = km < 100 ? km.toStringAsFixed(1) : km.round().toString();
    return (value, 'km');
  }

  static (String, String)? speed(double? metersPerSecond) {
    if (metersPerSecond == null) return null;
    return ('${(metersPerSecond * 3.6).round()}', 'km/h');
  }

  /// Thousands-separated ("1,240 m") - the one stat large enough to need
  /// it. No `intl` dependency for just this: a few lines beats a whole
  /// package for one comma rule.
  static (String, String)? elevation(double? meters) {
    if (meters == null) return null;
    final value = meters.round();
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return ('${value < 0 ? '-' : ''}$buffer', 'm');
  }
}
