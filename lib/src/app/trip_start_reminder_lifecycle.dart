import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/domain/app_feature_flags.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/detection/data/trip_start_reminder_state.dart';
import '../features/journeys/application/journey_entitlement.dart';
import '../features/journeys/application/journey_recorder.dart';
import '../features/journeys/domain/journey_recording.dart';
import '../features/profile/application/profile_settings_providers.dart';
import '../services/app_logger.dart';

/// Keeps what the "record your trip" reminder needs in step with the app.
/// The reminder itself is posted by the geofence callback with the app
/// closed (no providers there), so this mirrors the Trip reminders switch,
/// whether this account can start a Trip (Pro, or free Trips left this
/// month), whether a Trip is recording, and when the last one ended into
/// shared preferences, the same way the arrival notification does.
class TripStartReminderLifecycle extends ConsumerStatefulWidget {
  const TripStartReminderLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TripStartReminderLifecycle> createState() =>
      _TripStartReminderLifecycleState();
}

class _TripStartReminderLifecycleState
    extends ConsumerState<TripStartReminderLifecycle>
    with WidgetsBindingObserver {
  static const _state = TripStartReminderState();

  bool? _active;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mirror();
      unawaited(_refreshAccess());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAccess());
    }
  }

  /// Pro / free Trips left, so a reminder is never sent to someone whose
  /// Start would hit the paywall. Best-effort: it never throws.
  Future<void> _refreshAccess() async {
    if (!AppFeatureFlags.journeys) return;
    if (ref.read(currentUserIdProvider)() == null) return;
    await ref.read(journeyEntitlementProvider.notifier).refreshAccess();
  }

  void _mirror() {
    final signedIn = ref.read(currentUserIdProvider)() != null;
    final enabled =
        ref.read(profileSettingsControllerProvider).value?.notifyTripAlerts ??
        true;
    final pro = ref.read(journeyEntitlementProvider);
    final trial = ref.read(journeyTrialUsageProvider);
    final eligible =
        AppFeatureFlags.journeys &&
        signedIn &&
        ((pro?.allowsStartAt(DateTime.now()) ?? false) ||
            (trial?.hasRemaining ?? false));
    final phase = ref.read(journeyRecorderProvider)?.recording.phase;
    final active =
        phase == JourneyRecordingPhase.recording ||
        phase == JourneyRecordingPhase.paused;
    final wasActive = _active;
    _active = active;
    unawaited(
      _write(
        enabled: enabled,
        eligible: eligible,
        active: active,
        // Only a Trip that was just running ended now.
        endedNow: wasActive == true && !active,
      ),
    );
  }

  Future<void> _write({
    required bool enabled,
    required bool eligible,
    required bool active,
    required bool endedNow,
  }) async {
    try {
      await _state.setEnabled(enabled);
      await _state.setEligible(eligible);
      await _state.setRecording(active, at: endedNow ? DateTime.now() : null);
    } on Object catch (error, stackTrace) {
      const AppLogger.detection().warning(
        'Could not save the trip reminder settings.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(journeyRecorderProvider, (_, _) => _mirror());
    ref.listen(profileSettingsControllerProvider, (_, _) => _mirror());
    ref.listen(journeyEntitlementProvider, (_, _) => _mirror());
    ref.listen(journeyTrialUsageProvider, (_, _) => _mirror());
    ref.listen(authUserIdProvider, (_, _) => _mirror());
    return widget.child;
  }
}
