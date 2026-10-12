/// The "Saved ..." copy for content shown from the copy kept on the phone:
/// just now, 9:41 AM (today), yesterday, 3 days ago, 3 weeks ago, then a
/// date (12 Aug) past two months. Null without a time.
///
/// [verboseToday] makes today's read "Saved today, 9:41 AM" (the banner).
String? savedAtLabel(
  DateTime? savedAt,
  DateTime now, {
  bool verboseToday = false,
}) {
  if (savedAt == null) return null;
  final local = savedAt.toLocal();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(local.year, local.month, local.day)).inDays;
  if (days <= 0) {
    if (now.difference(local).inMinutes < 1) return 'Saved just now';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
    return verboseToday ? 'Saved today, $time' : 'Saved $time';
  }
  if (days == 1) return 'Saved yesterday';
  if (days < 14) return 'Saved $days days ago';
  if (days < 60) return 'Saved ${days ~/ 7} weeks ago';
  const months = [
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
  return 'Saved ${local.day} ${months[local.month - 1]}';
}
