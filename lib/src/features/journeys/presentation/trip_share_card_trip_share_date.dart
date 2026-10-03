part of 'trip_share_card.dart';

/// "Thu 1 Oct" / "Thu 1 Oct 2026" for a single-day Trip; "12-14 Sep" /
/// "12-14 Sep 2026" for one spanning several calendar days locally, or
/// "30 Sep - 2 Oct" across a month boundary.
abstract final class _TripShareDate {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String format(
    DateTime startedAt,
    DateTime endedAt, {
    required bool includeYear,
  }) {
    final start = startedAt.toLocal();
    final end = endedAt.toLocal();
    final year = includeYear ? ' ${end.year}' : '';
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return '${_weekdays[start.weekday - 1]} ${start.day} '
          '${_months[start.month - 1]}$year';
    }
    if (start.year == end.year && start.month == end.month) {
      return '${start.day}-${end.day} ${_months[start.month - 1]}$year';
    }
    return '${start.day} ${_months[start.month - 1]} - '
        '${end.day} ${_months[end.month - 1]}$year';
  }
}
