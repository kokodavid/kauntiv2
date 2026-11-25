/// Month and week arithmetic for the plan date picker. Weeks start on
/// Monday, as in Kenya.
abstract final class PlanCalendar {
  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// One letter per weekday, Monday first.
  static const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// The first day of each month from [first]'s through [last]'s.
  static List<DateTime> months(DateTime first, DateTime last) {
    final out = <DateTime>[];
    var month = DateTime(first.year, first.month);
    final end = DateTime(last.year, last.month);
    while (!month.isAfter(end)) {
      out.add(month);
      month = DateTime(month.year, month.month + 1);
    }
    return out;
  }

  /// The month's days laid out in weeks of seven (Monday first): leading and
  /// trailing blanks are null. Always a multiple of 7 long.
  static List<DateTime?> grid(DateTime month) {
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[
      for (var i = 0; i < first.weekday - 1; i++) null,
      for (var d = 1; d <= days; d++) DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  /// "Friday 30 October 2026", for screen readers.
  static String spoken(DateTime d) =>
      '${weekdayNames[d.weekday - 1]} ${d.day} '
      '${monthNames[d.month - 1]} ${d.year}';
}
