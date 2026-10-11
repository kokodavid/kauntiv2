/// "Saved today, 9:41 AM" / "Saved yesterday" / "Saved 3 weeks ago", for
/// screens shown from a copy kept on the phone. Null without a time.
String? savedAtLabel(DateTime? savedAt, DateTime now) {
  if (savedAt == null) return null;
  final local = savedAt.toLocal();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(local.year, local.month, local.day)).inDays;
  if (days <= 0) {
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Saved today, $hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
  }
  if (days == 1) return 'Saved yesterday';
  if (days < 14) return 'Saved $days days ago';
  if (days < 60) return 'Saved ${days ~/ 7} weeks ago';
  return 'Saved ${days ~/ 30} months ago';
}
