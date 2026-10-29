/// Dates, distances and drive times as the planner writes them. Drive times
/// are always estimates ("about 1 h 10 min").
abstract final class PlanLabels {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// "Sat 14 Nov".
  static String day(DateTime date) =>
      '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';

  /// "14 – 15 Nov", "30 Nov – 2 Dec", "3 Oct" or "No date yet".
  static String range(DateTime? start, DateTime? end) {
    if (start == null) return 'No date yet';
    final last = end ?? start;
    if (_sameDay(start, last)) {
      return '${start.day} ${_months[start.month - 1]}';
    }
    if (start.month == last.month && start.year == last.year) {
      return '${start.day} – ${last.day} ${_months[last.month - 1]}';
    }
    return '${start.day} ${_months[start.month - 1]} – '
        '${last.day} ${_months[last.month - 1]}';
  }

  /// "Sat 14 – Sun 15 Nov" for a plan header.
  static String longRange(DateTime? start, DateTime? end) {
    if (start == null) return 'No date yet';
    final last = end ?? start;
    if (_sameDay(start, last)) return day(start);
    final from = start.month == last.month
        ? '${_weekdays[start.weekday - 1]} ${start.day}'
        : day(start);
    return '$from – ${day(last)}';
  }

  /// "1 day", "3 days".
  static String days(int count) => count == 1 ? '1 day' : '$count days';

  /// "about 1 h 10 min", "about 45 min".
  static String drive(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return 'about ${minutes < 1 ? 1 : minutes} min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? 'about $h h' : 'about $h h $m min';
  }

  /// "62 km", "800 m".
  static String distance(int meters) {
    if (meters < 1000) return '${(meters / 50).round() * 50} m';
    return '${(meters / 1000).round()} km';
  }

  /// "Passes through 5 counties · 3 new", or null when nothing is known.
  static String? counties(int count, int newCount) {
    if (count == 0) return null;
    final base = count == 1
        ? 'Passes through 1 county'
        : 'Passes through $count counties';
    return newCount == 0 ? base : '$base · $newCount new';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// How long ago something changed, for "Updated by nyati7 · 2 min ago".
  /// Null when it is missing or more than a week old.
  static String? ago(DateTime? at, DateTime now) {
    if (at == null) return null;
    final gap = now.difference(at);
    if (gap.isNegative || gap.inMinutes < 1) return 'just now';
    if (gap.inMinutes < 60) return '${gap.inMinutes} min ago';
    if (gap.inHours < 24) return '${gap.inHours} h ago';
    if (gap.inDays < 7) return '${gap.inDays} d ago';
    return null;
  }

  /// Within the last few minutes: worth a highlight on the plan screen.
  static bool isFresh(DateTime? at, DateTime now) =>
      at != null && now.difference(at) < const Duration(minutes: 3);
}
