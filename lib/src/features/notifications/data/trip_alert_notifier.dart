import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/trip_alert.dart';

/// The "your trip is paused" reminder, scheduled with the OS so it still
/// fires after the app is closed. One reminder at a time (a fixed id), and
/// nothing leaves the phone.
class TripAlertNotifier {
  TripAlertNotifier({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _id = 4701;
  static const _channelId = 'trip_alerts';

  final FlutterLocalNotificationsPlugin _plugin;

  /// Replaces any earlier reminder. The plugin is initialised by the
  /// arrival notification bridge at app start.
  Future<void> schedule(DateTime at) {
    return _plugin.zonedSchedule(
      _id,
      'Your trip is paused',
      'Tap to resume recording.',
      tz.TZDateTime.from(at, tz.UTC),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Trip reminders',
          channelDescription: 'When a trip you are recording is paused.',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: tripPausedPayload,
    );
  }

  Future<void> cancel() => _plugin.cancel(_id);
}
