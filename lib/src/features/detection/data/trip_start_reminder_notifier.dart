import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/services/location_diagnostics.dart';
import '../../../services/app_logger.dart';
import '../domain/trip_start_reminder_rules.dart';
import 'arrival_notification_state.dart';
import 'trip_start_reminder_state.dart';

/// Posts "Looks like you're on a trip" from the geofence callback (app
/// closed, no providers, no network) when a county crossing shows the
/// person is moving and no Trip is recording. Everything is local: no
/// location leaves the phone for this. The plugin is initialised by the
/// arrival notifier in the same callback.
class TripStartReminderNotifier {
  TripStartReminderNotifier({
    FlutterLocalNotificationsPlugin? plugin,
    this.state = const TripStartReminderState(),
    this.appState = const ArrivalNotificationState(),
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _logger = AppLogger.detection();
  static const _id = 4702;
  static const _channelId = 'trip_start_reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  final TripStartReminderState state;
  final ArrivalNotificationState appState;

  /// True when the reminder was posted. Quiet when the app is in front
  /// (it has its own Trip controls) and when the OS doesn't allow
  /// notifications.
  Future<bool> postIfDue({DateTime? now}) async {
    final at = now ?? DateTime.now();
    if (await appState.inForeground(now: at)) return _skipped('app_in_front');
    final due = TripStartReminderRules.isDue(
      enabled: await state.enabled(),
      eligible: await state.eligible(),
      recording: await state.recording(),
      now: at,
      lastTripEndedAt: await state.lastTripEndedAt(),
      lastRemindedAt: await state.lastRemindedAt(),
    );
    if (!due) return _skipped('not_due');
    if (!await _permitted()) return _skipped('permission_not_granted');

    await _plugin.show(
      _id,
      "Looks like you're on a trip",
      'Tap to record it.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Trip start reminders',
          channelDescription:
              'When you seem to be travelling between counties.',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: tripStartPayload,
    );
    await state.markReminded(now: at);
    await LocationDiagnostics.record('trip_start_reminder', {
      'result': 'posted',
    });
    return true;
  }

  Future<bool> _permitted() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return (await ios?.checkPermissions())?.isEnabled ?? false;
  }

  Future<bool> _skipped(String reason) async {
    _logger.info('Trip start reminder skipped: $reason.');
    await LocationDiagnostics.record('trip_start_reminder', {
      'result': 'skipped',
      'reason': reason,
    });
    return false;
  }
}
