import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../services/app_logger.dart';
import '../domain/detection_status.dart';
import '../domain/reduced_detection_plan.dart';

/// One local notice when detection has been reduced or off for a day. It is
/// scheduled when the tier drops (so it fires with the app closed) and
/// cancelled if detection recovers first. State is in shared preferences:
/// when the episode began and whether its notice was already scheduled.
/// Needs the plugin initialised (see `ArrivalNotifier.initialize`).
class ReducedDetectionNotifier {
  ReducedDetectionNotifier({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _logger = AppLogger.detection();
  static const _channelId = 'detection_health';
  static const _id = 6000;
  static const _sinceKey = 'detection.reduced.since_ms';
  static const _scheduledKey = 'detection.reduced.scheduled';

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> sync(DetectionStatus status, {DateTime? now}) async {
    try {
      final at = now ?? DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final sinceMs = prefs.getInt(_sinceKey);
      final plan = ReducedDetectionPlan.decide(
        tier: status.tier,
        now: at,
        since: sinceMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(sinceMs, isUtc: true),
        scheduledThisEpisode: prefs.getBool(_scheduledKey) ?? false,
      );
      switch (plan.action) {
        case ReducedAction.none:
          break;
        case ReducedAction.cancel:
          await _plugin.cancel(_id);
          await prefs.remove(_sinceKey);
          await prefs.remove(_scheduledKey);
        case ReducedAction.schedule:
          final copy = ReducedDetectionPlan.copy(status.reason);
          await _plugin.zonedSchedule(
            _id,
            copy.title,
            copy.body,
            tz.TZDateTime.from(plan.at!, tz.UTC),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                'Detection health',
                channelDescription: 'When county detection has stopped.',
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          await prefs.setInt(
            _sinceKey,
            plan.since!.toUtc().millisecondsSinceEpoch,
          );
          await prefs.setBool(_scheduledKey, true);
      }
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Reduced-detection notice sync failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
