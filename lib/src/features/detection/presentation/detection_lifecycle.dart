import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_config_provider.dart';
import '../../../core/services/location_diagnostics.dart';
import '../../../services/app_logger.dart';
import '../../discover/application/explore_providers.dart';
import '../../discover/domain/county_detail.dart';
import '../../notifications/domain/trip_alert.dart';
import '../../profile/application/profile_settings_providers.dart';
import '../application/arrival_notification_bridge.dart';
import '../application/arrival_nudge.dart';
import '../application/detection_controller.dart';
import '../domain/detection_status.dart';
import '../domain/foreground_fix_policy.dart';
import '../domain/trip_start_reminder_rules.dart';
import '../domain/visit_models.dart';
import 'county_arrival_sheet.dart';
import 'detection_tiers_sheet.dart';

/// Drives [DetectionController] from the app lifecycle: a cycle on start,
/// on every resume, and every 15 s while the app is in front. It reads
/// hardware location on start/resume, and after that only while a visit is
/// pending (see [ForegroundFixPolicy]); other cycles process local
/// dwell/sync state without polling GPS. The timer stops in background,
/// where detection is the OS geofences' job.
///
/// It also hosts the arrival sheet: when a cycle offers a new crossing,
/// the sheet opens over whatever tab is showing (v1 listened on Home,
/// which the tab shell keeps mounted, so the effect is the same).
///
/// Wraps the signed-in, onboarded app only (location granted), so nothing
/// here runs before onboarding.
class DetectionLifecycle extends ConsumerStatefulWidget {
  const DetectionLifecycle({
    super.key,
    required this.child,
    this.homeCountyCode,
    this.onOpenCounty,
    this.onOpenPlace,
    this.onOpenTrip,
    this.onOpenTripStart,
  });

  final Widget child;

  /// Fallback for the first cycle when no fix is available.
  final int? homeCountyCode;

  /// County / Place Detail from the arrival sheet, supplied by `app/`.
  final void Function(BuildContext context, int countyCode)? onOpenCounty;
  final void Function(BuildContext context, String placeId)? onOpenPlace;

  /// The recording screen, for a tapped "your trip is paused" reminder.
  final void Function(BuildContext context)? onOpenTrip;

  /// Where to start a Trip, for a tapped "Looks like you're on a trip"
  /// reminder.
  final void Function(BuildContext context)? onOpenTripStart;

  @override
  ConsumerState<DetectionLifecycle> createState() => _DetectionLifecycleState();
}

class _DetectionLifecycleState extends ConsumerState<DetectionLifecycle>
    with WidgetsBindingObserver {
  static const _interval = Duration(seconds: 15);
  Timer? _timer;
  DateTime? _lastLocationReadAt;
  final _notifications = ArrivalNotificationBridge();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recordLifecycle('app_foregrounded');
    _run(forceLocation: true);
    _startTimer();
    unawaited(_notifications.syncHomeCounty(widget.homeCountyCode));
    unawaited(
      _notifications.start(
        onOpen: _openFromNotification,
        onOtherPayload: _openOtherPayload,
      ),
    );
  }

  @override
  void didUpdateWidget(DetectionLifecycle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.homeCountyCode != widget.homeCountyCode) {
      unawaited(_notifications.syncHomeCounty(widget.homeCountyCode));
    }
  }

  @override
  void dispose() {
    unawaited(_notifications.beat(foreground: false));
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recordLifecycle('app_foregrounded');
      _run(forceLocation: true);
      _startTimer();
    } else {
      _recordLifecycle('app_lifecycle_${state.name}');
      unawaited(_notifications.beat(foreground: false));
      _timer?.cancel();
      _timer = null;
    }
  }

  void _recordLifecycle(String event) {
    final config = ref.read(appConfigProvider);
    if (!LocationDiagnostics.enabledFor(isDev: config.isDev)) return;
    unawaited(() async {
      if (!await LocationDiagnostics.isActive()) return;
      final battery = await LocationDiagnostics.batteryPercent();
      await LocationDiagnostics.record(event, {'battery_percent': battery});
    }());
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _run());
  }

  void _run({bool forceLocation = false}) {
    final now = DateTime.now();
    final refreshLocation = ForegroundFixPolicy.shouldRead(
      forced: forceLocation,
      hasPending: ref
          .read(detectionControllerProvider)
          .activeCandidates
          .isNotEmpty,
      now: now,
      lastReadAt: _lastLocationReadAt,
    );
    if (refreshLocation) _lastLocationReadAt = now;
    // The geofence callback stays quiet while the app is in front: the
    // sheet covers an arrival, and a notification would only repeat it.
    unawaited(_notifications.beat(foreground: true));
    unawaited(
      ref
          .read(detectionControllerProvider.notifier)
          .runCycle(
            homeCountyCode: widget.homeCountyCode,
            refreshLocation: refreshLocation,
          ),
    );
  }

  void _showArrival() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(pendingArrivalNudgeProvider.notifier).take();
      if (pending == null) return;
      unawaited(_present(pending.county));
    });
  }

  /// A tapped notification that is not an arrival: the paused-trip reminder
  /// (back to the recording) or the start-a-trip reminder (to where a Trip
  /// starts). Deferred a frame so a cold start has a navigator.
  void _openOtherPayload(String payload) {
    final open = switch (payload) {
      tripPausedPayload => widget.onOpenTrip,
      tripStartPayload => widget.onOpenTripStart,
      _ => null,
    };
    if (open == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) open(context);
    });
  }

  /// A tapped arrival notification: opens the sheet for that crossing, once.
  /// The sheet the cycle may already have pending for the same county is
  /// reused so the two never stack.
  Future<void> _openFromNotification(CountyArrivalNudge nudge) async {
    try {
      final notifier = ref.read(pendingArrivalNudgeProvider.notifier);
      final pending = ref.read(pendingArrivalNudgeProvider);
      CountyDetailData? county;
      if (pending?.nudge.countyCode == nudge.countyCode) {
        county = notifier.take()?.county;
      }
      county ??= await ref
          .read(discoverDetailRepositoryProvider)
          .countyDetail(nudge.countyCode);
      if (!mounted) return;
      await ref.read(arrivalNudgeHistoryProvider).markShown(nudge);
      if (!mounted) return;
      await _present(county);
    } on Object catch (error, stackTrace) {
      const AppLogger.detection().warning(
        'Could not open the arrival sheet from a notification.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The second permission ask: once, after the first claimed county, for a
  /// user who only allowed "While using".
  Future<void> _askForAlwaysOnce(DetectionTier tier, int claimed) async {
    final ask = await ref
        .read(detectionControllerProvider.notifier)
        .takeAlwaysAsk(tier: tier, claimed: claimed);
    if (!ask || !mounted) return;
    await showDetectionTiersSheet(context, afterFirstCounty: true);
  }

  Future<void> _present(CountyDetailData data) async {
    final openCounty = widget.onOpenCounty;
    final openPlace = widget.onOpenPlace;
    await showCountyArrivalSheet(
      context,
      data: data,
      onOpenCounty: openCounty == null
          ? null
          : (code) => openCounty(context, code),
      onOpenPlace: openPlace == null ? null : (id) => openPlace(context, id),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingArrivalNudgeProvider, (previous, next) {
      if (next != null) _showArrival();
    });
    ref.listen(detectionControllerProvider, (previous, next) {
      final claimed = next.resolved
          .where((v) => v.outcome == VisitOutcome.explored)
          .length;
      if (claimed > 0 && !identical(previous?.resolved, next.resolved)) {
        unawaited(_askForAlwaysOnce(next.status.tier, claimed));
      }
    });
    ref.listen(profileSettingsControllerProvider, (previous, next) {
      final settings = next.value;
      if (settings != null) {
        unawaited(_notifications.syncEnabled(settings.notifyCountyNudges));
      }
    });
    return widget.child;
  }
}
