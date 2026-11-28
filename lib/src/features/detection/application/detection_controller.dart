import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/app_feature_flags.dart';
import '../../../core/services/app_config_provider.dart';
import '../../../core/services/app_current_location.dart';
import '../../../core/services/location_diagnostics.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../../../services/app_logger.dart';
import '../../auth/application/auth_providers.dart';
import '../../discover/application/explore_providers.dart';
import '../data/always_ask_state.dart';
import '../data/claim_notifier.dart';
import '../data/detection_health_reporter.dart';
import '../data/detection_heartbeat.dart';
import '../data/detection_outcome_counts.dart';
import '../data/detection_repository.dart';
import '../data/geofence_service.dart';
import '../data/reduced_detection_notifier.dart';
import '../domain/detection_health_report.dart';
import '../domain/detection_status.dart';
import '../domain/visit_models.dart';
import 'arrival_nudge.dart';
import 'detection_bootstrap.dart';
import 'detection_providers.dart';
import 'detection_snapshot.dart';
import 'visit_sync.dart';

export 'detection_snapshot.dart';

part 'detection_controller.g.dart';

/// One foreground location read for detection; null when unavailable.
/// Tests override it.
@Riverpod(keepAlive: true)
Future<AppLocationReading?> Function() detectionLocationReader(Ref ref) =>
    () => AppCurrentLocation.readDetailed(timeout: const Duration(seconds: 5));

/// Detection's foreground cycle (v1 `GeofenceLifecycleObserver`, moved out
/// of the widget): run on start, on resume and every 15 s while the app is
/// in front. Hardware location is reconciled less often by the lifecycle.
/// Each run:
///
/// 1. optionally reads a fix and, the first time, seeds the current county
///    from it (else the home county) and registers geofences;
/// 2. when a fix was read, reconciles the current county (an OS-missed
///    crossing becomes a normal exit / enter);
/// 3. captures active candidates, then resolves any past the 2 h dwell;
/// 4. uploads the queue;
/// 5. refreshes the geofence window when a hardware fix was reconciled;
/// 6. offers the newest unseen crossing to the arrival sheet.
///
/// Before any of that it checks permission. Without background location
/// the geofences are removed once but the cycle carries on: a fix is read,
/// the county reconciled and dwell checked, so a visit is still recorded
/// when the app is open. The snapshot flags it so Home can offer "Always".
/// With no location permission at all nothing is read; the queue still
/// uploads and Home says detection is off.
///
/// The fix only decides the county and is never stored (doc 05). A
/// failure is logged and the next run retries.
@Riverpod(keepAlive: true)
class DetectionController extends _$DetectionController {
  static const _logger = AppLogger.detection();
  bool _running = false;
  bool _suspended = false;
  Completer<void>? _cycleDone;

  @override
  DetectionSnapshot build() {
    ref.listen(authUserIdProvider, (previous, next) {
      if (next.hasValue &&
          next.value != null &&
          next.value != previous?.value) {
        _suspended = false;
      }
    });
    return const DetectionSnapshot();
  }

  /// Remove OS geofences before the account is detached. An in-flight cycle
  /// may finish its current read, but cannot register another window.
  Future<void> suspendForSignOut() async {
    _suspended = true;
    final cycle = _cycleDone;
    if (cycle != null) await cycle.future;
    final geofences = ref.read(geofenceServiceProvider);
    await geofences.initialize();
    await geofences.removeAll();
    state = const DetectionSnapshot();
  }

  void resumeAfterSignOutFailure() {
    if (ref.read(currentUserIdProvider)() != null) _suspended = false;
  }

  Future<void> runCycle({
    int? homeCountyCode,
    bool refreshLocation = true,
  }) async {
    if (_running || _suspended) return;
    _running = true;
    final cycleStartedAt = DateTime.now();
    var permissionGranted = true;
    var backgroundOff = false;
    var foregroundOk = true;
    var enteredCounty = false;
    var resolvedCount = 0;
    final diagnosticsEnabled =
        AppFeatureFlags.locationDiagnostics &&
        LocationDiagnostics.enabledFor(
          isDev: ref.read(appConfigProvider).isDev,
        );
    final cycleDone = Completer<void>();
    _cycleDone = cycleDone;
    try {
      final repository = ref.read(detectionRepositoryProvider);
      final geofences = ref.read(geofenceServiceProvider);
      final permission = ref.read(detectionPermissionProvider);
      if (!await permission.backgroundGranted()) {
        backgroundOff = true;
        await _dropGeofences(geofences);
        if (!await permission.foregroundGranted()) {
          permissionGranted = false;
          foregroundOk = false;
          await _pause(
            await const DetectionHeartbeat().statusNow(
              backgroundGranted: false,
              foregroundGranted: false,
              servicesEnabled: true,
            ),
          );
          return;
        }
      }
      if (!await permission.servicesEnabled()) {
        state = DetectionSnapshot(
          currentCounty: state.currentCounty,
          lastRunAt: DateTime.now(),
          status: await const DetectionHeartbeat().statusNow(
            backgroundGranted: !backgroundOff,
            foregroundGranted: foregroundOk,
            servicesEnabled: false,
          ),
        );
        await ref.read(visitSyncProvider.notifier).drain();
        return;
      }
      final fix = refreshLocation
          ? await ref.read(detectionLocationReaderProvider)()
          : null;
      if (_suspended) return;

      final bootstrapped = await DetectionBootstrap(
        repository: repository,
        geofences: geofences,
      ).run(fix, homeCountyCode, registerGeofences: !backgroundOff);
      final entered = fix == null || bootstrapped
          ? null
          : await repository.reconcileCurrentLocation(
              latitude: fix.latitude,
              longitude: fix.longitude,
              accuracyMeters: fix.accuracyMeters,
            );
      enteredCounty = entered != null;
      final candidates = await repository.activeArrivalCandidates();
      final resolved = await repository.checkStillActiveCandidates();
      resolvedCount = resolved.length;
      final claimed = resolved
          .where((v) => v.outcome == VisitOutcome.explored)
          .length;
      if (claimed > 0) {
        await const DetectionOutcomeCounts().add(
          DetectionOutcome.claimed,
          claimed,
        );
      }

      await ref.read(visitSyncProvider.notifier).drain();
      if (_suspended) return;

      // iOS: keep the "county claimed" notifications matching what is
      // still pending (a no-op on Android).
      await ClaimNotifier(
        dwell: ref.read(visitTimingsProvider).dwellThreshold,
      ).sync(await repository.activeArrivalCandidates());

      final current = await repository.currentCountyCode();
      if (current != null &&
          refreshLocation &&
          !bootstrapped &&
          !backgroundOff) {
        await geofences.initialize();
        await geofences.registerWindowFor(current);
      }
      if (entered != null || resolved.isNotEmpty) {
        ref.invalidate(exploreBoardProvider);
      }
      await ref
          .read(pendingArrivalNudgeProvider.notifier)
          .offer(candidates, homeCountyCode: homeCountyCode);
      state = DetectionSnapshot(
        currentCounty: current,
        activeCandidates: candidates,
        resolved: resolved,
        lastRunAt: DateTime.now(),
        status: await const DetectionHeartbeat().statusNow(
          backgroundGranted: !backgroundOff,
          foregroundGranted: foregroundOk,
          servicesEnabled: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Detection cycle failed.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (diagnosticsEnabled) {
        unawaited(
          LocationDiagnostics.record('detection_cycle', {
            'duration_ms': DateTime.now()
                .difference(cycleStartedAt)
                .inMilliseconds,
            'gps_read': refreshLocation,
            'permission_granted': permissionGranted,
            'crossing_reconciled': enteredCounty,
            'visits_resolved': resolvedCount,
          }),
        );
      }
      _reportHealth();
      _running = false;
      _cycleDone = null;
      cycleDone.complete();
    }
  }

  /// Keeps the one "detection is reduced" notice in step with the tier, and
  /// sends this cycle's status to the team's health table when one is due
  /// (first time, tier change, daily; signed-in users only).
  void _reportHealth() {
    unawaited(ReducedDetectionNotifier().sync(state.status));
    final client = ref.read(supabaseClientProvider);
    if (client == null || client.auth.currentUser == null) return;
    unawaited(
      DetectionHealthReporter.supabase(client).maybeReport(state.status),
    );
  }

  /// Background location is off: stop OS monitoring, once. The foreground
  /// cycle carries on without it.
  Future<void> _dropGeofences(GeofenceService geofences) async {
    if (state.backgroundLocationOff) return;
    await geofences.initialize();
    await geofences.removeAll();
    _logger.info('Background location off: geofences removed, catch-up only.');
  }

  /// No location permission at all: read nothing, keep uploading what's
  /// already queued, and flag it for Home.
  Future<void> _pause(DetectionStatus status) async {
    state = DetectionSnapshot(
      currentCounty: state.currentCounty,
      lastRunAt: DateTime.now(),
      status: status,
    );
    await ref.read(visitSyncProvider.notifier).drain();
  }

  /// Opens the OS settings so the user can give "Always" back; the next
  /// resume re-checks it.
  Future<void> openLocationSettings() =>
      ref.read(detectionPermissionProvider).openSettings();

  /// True once, for the second permission ask after a first claimed county;
  /// marks it shown so it never repeats.
  Future<bool> takeAlwaysAsk({
    required DetectionTier tier,
    required int claimed,
  }) => const AlwaysAskState().take(tier: tier, claimed: claimed);

  /// Asks for "All the time" (iOS prompt or Settings); the next resume
  /// re-checks it.
  Future<void> askForAlways() async {
    await ref.read(detectionPermissionProvider).askForAlways();
    await runCycle();
  }

  /// Asks the phone to switch location back on, then checks again (on
  /// Android the dialog doesn't leave the app, so no resume follows).
  Future<void> turnOnLocation() async {
    await ref.read(detectionPermissionProvider).turnOnServices();
    await runCycle();
  }
}
