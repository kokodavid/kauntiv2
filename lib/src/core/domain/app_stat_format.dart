/// Formats county and place stats (Area / Elevation / Duration) the same
/// way everywhere: "3,108 KM²", "2,348m", "20h".
abstract final class AppStatFormat {
  static String area(num km2) => '${thousands(km2.round())} KM²';

  static String elevation(num metres) => '${thousands(metres.round())}m';

  static String duration(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '${rest}m';
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}m';
  }

  static String thousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// The stats that are on file, as (value, label), in display order.
  static List<({String value, String label})> stats({
    num? areaKm2,
    num? elevationM,
    int? durationMinutes,
  }) => [
    if (areaKm2 != null) (value: area(areaKm2), label: 'Area'),
    if (elevationM != null) (value: elevation(elevationM), label: 'Elevation'),
    if (durationMinutes != null)
      (value: duration(durationMinutes), label: 'Duration'),
  ];
}
