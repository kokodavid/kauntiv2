import 'dart:async';

import '../../../services/app_logger.dart';
import '../data/arrival_notification_state.dart';
import '../data/arrival_notifier.dart';
import '../domain/arrival_nudge_rules.dart';
import '../domain/visit_models.dart';

/// The app-side half of the arrival notification (the geofence callback
/// posts it). It mirrors what the callback needs into
/// [ArrivalNotificationState] (home county, the nudge switch, whether the
/// app is in front), turns a tap into a crossing for the arrival sheet,
/// and asks for the OS permission once. Every call is best effort: a
/// notification problem must never reach the screen.
class ArrivalNotificationBridge {
  ArrivalNotificationBridge({
    ArrivalNotifier? notifier,
    this.state = const ArrivalNotificationState(),
  }) : _notifier = notifier ?? ArrivalNotifier();

  static const _logger = AppLogger.detection();

  final ArrivalNotifier _notifier;
  final ArrivalNotificationState state;

  /// Registers the tap handler and reports the crossing of a notification
  /// that cold-started the app. [onOpen] runs for either.
  Future<void> start({
    required void Function(CountyArrivalNudge) onOpen,
    void Function(String payload)? onOtherPayload,
  }) {
    return _guard('start', () async {
      void open(String payload) {
        final nudge = ArrivalNudgeRules.parseKey(payload);
        if (nudge != null) {
          onOpen(nudge);
        } else {
          onOtherPayload?.call(payload);
        }
      }

      await _notifier.initialize(onTap: open);
      final launch = await _notifier.launchPayload();
      if (launch != null) open(launch);
    });
  }

  Future<void> syncHomeCounty(int? code) =>
      _guard('home county', () => state.setHomeCounty(code));

  Future<void> syncEnabled(bool enabled) =>
      _guard('switch', () => state.setEnabled(enabled));

  Future<void> beat({required bool foreground}) =>
      _guard('heartbeat', () => state.setForeground(foreground));

  Future<void> _guard(String what, Future<void> Function() run) async {
    try {
      await run();
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Arrival notification ($what) failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
