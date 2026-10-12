import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../counties/county_paths.dart';
import '../../../services/app_logger.dart';
import '../domain/arrival_nudge_rules.dart';
import '../domain/visit_models.dart';
import 'arrival_notification_state.dart';
import 'arrival_nudge_history.dart';

/// Posts the "you crossed into X" notification from the geofence callback
/// (app closed, no providers, no network) and reports the tap back to the
/// app. Which crossing is due is [ArrivalNudgeRules.pick], the same rules
/// as the sheet; the home county, the `notify_county_nudges` switch and
/// the foreground heartbeat come from [ArrivalNotificationState].
///
/// Everything is local: no location or visit leaves the phone for this.
class ArrivalNotifier {
  ArrivalNotifier({
    FlutterLocalNotificationsPlugin? plugin,
    this.history = const ArrivalNudgeHistory(),
    this.state = const ArrivalNotificationState(),
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _logger = AppLogger.detection();
  static const _channelId = 'county_arrivals';

  final FlutterLocalNotificationsPlugin _plugin;
  final ArrivalNudgeHistory history;
  final ArrivalNotificationState state;

  /// Safe to call in any isolate. [onTap] only matters in the app's own
  /// isolate: it gets the payload (a crossing key) of a notification
  /// tapped while the process is alive.
  Future<void> initialize({void Function(String payload)? onTap}) {
    return _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // The prompt is shown in context, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && onTap != null) onTap(payload);
      },
    );
  }

  /// The payload of the notification that cold-started the app, once.
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  /// The OS prompt (Android 13+, iOS). True when notifications are allowed.
  Future<bool> requestPermission() async {
    await state.markPermissionAsked();
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// Whether the OS currently allows notifications (always true on
  /// Android before 13, which has no prompt).
  Future<bool> isPermitted() async {
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return (await ios?.checkPermissions())?.isEnabled ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.areNotificationsEnabled() ?? false;
  }

  /// Posts the notification for the newest crossing in [candidates] that
  /// is due; true when one was posted. Quiet when the switch is off, the
  /// home county is unknown or the crossing, or its county's cooldown, was
  /// already handled, when the app is in front (the sheet covers it) and
  /// when the OS permission isn't granted.
  Future<bool> notifyIfDue(
    List<CountyArrivalNudge> candidates, {
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    if (!await state.enabled()) return false;
    final home = await state.homeCounty();
    if (home == null) return false;
    if (await state.inForeground(now: at)) return false;

    final lastShown = await history.lastShownByCounty();
    (await state.lastNotifiedByCounty()).forEach((code, notifiedAt) {
      final known = lastShown[code];
      if (known == null || notifiedAt.isAfter(known)) {
        lastShown[code] = notifiedAt;
      }
    });
    final nudge = ArrivalNudgeRules.pick(
      candidates,
      suppressed: {home},
      shown: {...await history.shownKeys(), ...await state.notifiedKeys()},
      lastShown: lastShown,
      now: at,
    );
    if (nudge == null || !await isPermitted()) return false;

    final county = CountyPaths.byCode[nudge.countyCode];
    if (county == null) return false;
    await _plugin.show(
      nudge.countyCode,
      'Welcome to ${county.name}',
      'See what to explore here.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'County arrivals',
          channelDescription: 'When you cross into a new county.',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: ArrivalNudgeRules.keyFor(nudge.countyCode, nudge.enteredAt),
    );
    await state.markNotified(nudge, now: at);
    _logger.info('Arrival notification posted for county ${nudge.countyCode}.');
    return true;
  }
}
