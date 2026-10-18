import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/app_logger.dart';
import '../../journeys/application/journey_recorder.dart';
import '../../journeys/domain/journey_recording.dart';
import '../../profile/application/profile_settings_providers.dart';
import '../application/trip_alert_providers.dart';
import '../domain/trip_alert.dart';

/// Reminds the person when a trip they are recording sits paused while the
/// app is out of sight. The reminder is scheduled with the OS when the app
/// goes to the background, and cancelled as soon as the app is back in
/// front, the trip resumes or ends, or the account changes. The paused
/// banner covers the in-app case.
class TripAlertLifecycle extends ConsumerStatefulWidget {
  const TripAlertLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TripAlertLifecycle> createState() => _TripAlertLifecycleState();
}

class _TripAlertLifecycleState extends ConsumerState<TripAlertLifecycle>
    with WidgetsBindingObserver {
  static const _logger = AppLogger.push();

  var _inBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _inBackground = false;
      unawaited(_cancel());
    } else if (state == AppLifecycleState.paused) {
      _inBackground = true;
      _scheduleIfPaused();
    }
  }

  void _scheduleIfPaused() {
    final recording = ref.read(journeyRecorderProvider)?.recording;
    final pausedAt = recording?.pausedAt;
    if (recording?.phase != JourneyRecordingPhase.paused || pausedAt == null) {
      return;
    }
    final enabled =
        ref.read(profileSettingsControllerProvider).value?.notifyTripAlerts ??
        true;
    if (!enabled) return;
    final now = DateTime.now();
    final due = pausedAt.add(tripPausedReminderDelay);
    final earliest = now.add(tripPausedReminderMinLead);
    final at = due.isAfter(earliest) ? due : earliest;
    final notifier = ref.read(tripAlertProvider);
    unawaited(_guard('schedule', () => notifier.schedule(at)));
  }

  Future<void> _cancel() =>
      _guard('cancel', () => ref.read(tripAlertProvider).cancel());

  Future<void> _guard(String what, Future<void> Function() run) async {
    try {
      await run();
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Trip reminder ($what) failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(journeyRecorderProvider, (previous, next) {
      final paused = next?.recording.phase == JourneyRecordingPhase.paused;
      if (!paused) {
        unawaited(_cancel());
      } else if (_inBackground) {
        _scheduleIfPaused();
      }
    });
    return widget.child;
  }
}
