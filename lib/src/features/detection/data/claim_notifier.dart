import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/location_diagnostics.dart';
import '../../../counties/county_paths.dart';
import '../../../services/app_logger.dart';
import '../domain/claim_notification_plan.dart';
import '../domain/visit_models.dart';
import '../domain/visit_rules.dart';
import 'arrival_notification_state.dart';

/// iOS only: there is no dwell event, so at entry a local notification is
/// scheduled for entry + the dwell threshold and cancelled when the phone
/// leaves first. Android keeps the OS dwell event and never schedules.
/// Runs in the app and in the geofence background isolate; the plugin
/// must already be initialised (see `ArrivalNotifier.initialize`).
class ClaimNotifier {
  ClaimNotifier({
    FlutterLocalNotificationsPlugin? plugin,
    this.state = const ArrivalNotificationState(),
    this.dwell = const Duration(seconds: 0),
    bool? enabledOnThisPlatform,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _enabled = enabledOnThisPlatform ?? Platform.isIOS;

  static const _logger = AppLogger.detection();
  static const _channelId = 'county_claims';

  /// Ids 5000 + county code, clear of the arrival ids (the bare county
  /// code) and the trip reminder.
  static const idBase = 5000;
  static const payloadPrefix = 'claim:';

  final FlutterLocalNotificationsPlugin _plugin;
  final ArrivalNotificationState state;
  final Duration dwell;
  final bool _enabled;

  Duration get _dwell =>
      dwell == Duration.zero ? VisitTimings.current.dwellThreshold : dwell;

  /// Makes the scheduled notifications match [candidates]. Safe to call as
  /// often as you like: ids are per county, so a repeat just replaces.
  Future<void> sync(
    List<CountyArrivalNudge> candidates, {
    DateTime? now,
  }) async {
    if (!_enabled) return;
    try {
      final at = now ?? DateTime.now();
      final pending = await _plugin.pendingNotificationRequests();
      final scheduled = {
        for (final p in pending)
          if (p.id > idBase && p.id < idBase + 100) p.id - idBase,
      };
      final allowed = await state.enabled();
      final plan = ClaimNotificationPlan.build(
        candidates: allowed ? candidates : const [],
        scheduled: scheduled,
        dwell: _dwell,
        now: at,
        homeCounty: await state.homeCounty(),
      );
      for (final code in plan.cancel) {
        await _plugin.cancel(idBase + code);
      }
      for (final claim in plan.schedule) {
        final county = CountyPaths.byCode[claim.countyCode];
        if (county == null) continue;
        await _plugin.zonedSchedule(
          idBase + claim.countyCode,
          '${county.name} is yours',
          'You stayed long enough. Open Kaunti47 to see it on your map.',
          tz.TZDateTime.from(claim.claimsAt, tz.UTC),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              'County claims',
              channelDescription: 'When a stay earns you a county.',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: '$payloadPrefix${claim.countyCode}',
        );
      }
      await LocationDiagnostics.record('claim_notification', {
        'scheduled': plan.schedule.length,
        'cancelled': plan.cancel.length,
      });
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Claim notification sync failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
