import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/services/app_current_location.dart';
import '../../../services/app_logger.dart';
import '../../discover/application/explore_providers.dart';
import '../data/detection_repository.dart';
import '../data/geofence_service.dart';
import '../domain/visit_models.dart';
import 'arrival_nudge.dart';
import 'detection_providers.dart';
import 'visit_sync.dart';

part 'detection_controller.g.dart';

/// One foreground location read for detection; null when unavailable.
/// Tests override it.
@Riverpod(keepAlive: true)
Future<AppLocationFix?> Function() detectionLocationReader(Ref ref) =>
    () => AppCurrentLocation.read(timeout: const Duration(seconds: 5));

/// What the last foreground cycle saw.
class DetectionSnapshot {
  const DetectionSnapshot({
    this.currentCounty,
    this.activeCandidates = const [],
    this.resolved = const [],
    this.lastRunAt,
    this.backgroundLocationOff = false,
  });

  final int? currentCounty;

  /// Counties being timed, captured before dwell resolution (the arrival
  /// sheet reads these).
  final List<CountyArrivalNudge> activeCandidates;

  /// Visits resolved by this cycle's dwell check.
  final List<ResolvedVisit> resolved;
  final DateTime? lastRunAt;

  /// Background location was taken away: geofences are removed and
  /// automatic detection is paused until it's granted again.
  final bool backgroundLocationOff;
}

/// Detection's foreground cycle (v1 `GeofenceLifecycleObserver`, moved out
/// of the widget): run on start, on resume and every 15 s while the app is
/// in front. Each run:
///
/// 1. reads one fix and, the first time, seeds the current county from it
///    (else the home county) and registers geofences;
/// 2. reconciles the current county from the fix (a crossing the OS
///    missed becomes a normal exit / enter);
/// 3. captures active candidates, then resolves any past the 2 h dwell;
/// 4. uploads the queue;
/// 5. re-registers the geofence window around the current county;
/// 6. offers the newest unseen crossing to the arrival sheet.
///
/// Before any of that it checks background location. Without it the
/// geofences are removed once, the queue still uploads, and the snapshot
/// says detection is paused (Home shows it) until access comes back.
///
/// The fix only decides the county and is never stored (doc 05). A
/// failure is logged and the next run retries.
@Riverpod(keepAlive: true)
class DetectionController extends _$DetectionController {
  static const _logger = AppLogger.detection();
  bool _running = false;

  @override
  DetectionSnapshot build() => const DetectionSnapshot();

  Future<void> runCycle({int? homeCountyCode}) async {
    if (_running) return;
    _running = true;
    try {
      final repository = ref.read(detectionRepositoryProvider);
      final geofences = ref.read(geofenceServiceProvider);
      if (!await ref.read(detectionPermissionProvider).backgroundGranted()) {
        await _pause(geofences);
        return;
      }
      final fix = await ref.read(detectionLocationReaderProvider)();

      final bootstrapped = await _bootstrapIfNeeded(
        repository,
        fix,
        homeCountyCode,
      );
      final entered = fix == null || bootstrapped
          ? null
          : await repository.reconcileCurrentLocation(
              latitude: fix.latitude,
              longitude: fix.longitude,
            );
      final candidates = await repository.activeArrivalCandidates();
      final resolved = await repository.checkStillActiveCandidates();

      await ref.read(visitSyncProvider.notifier).drain();

      final current = await repository.currentCountyCode();
      if (current != null) {
        await geofences.initialize();
        if (!bootstrapped) await geofences.registerWindowFor(current);
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
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Detection cycle failed.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _running = false;
    }
  }

  /// Background location is off: stop monitoring (once), keep uploading
  /// what's already queued, and flag it for Home.
  Future<void> _pause(GeofenceService geofences) async {
    if (!state.backgroundLocationOff) {
      await geofences.initialize();
      await geofences.removeAll();
      _logger.info('Background location off: detection paused.');
    }
    state = DetectionSnapshot(
      currentCounty: state.currentCounty,
      lastRunAt: DateTime.now(),
      backgroundLocationOff: true,
    );
    await ref.read(visitSyncProvider.notifier).drain();
  }

  /// Opens the OS settings so the user can give "Always" back; the next
  /// resume re-checks it.
  Future<void> openLocationSettings() =>
      ref.read(detectionPermissionProvider).openSettings();

  /// First run after onboarding: the phone's county comes from the fix
  /// (the home county is a preference, not where the phone is), falling
  /// back to the home county. The OS is asked to report an ENTER for the
  /// county the phone is already in, unless the fix shows it's elsewhere.
  Future<bool> _bootstrapIfNeeded(
    DetectionRepository repository,
    AppLocationFix? fix,
    int? homeCountyCode,
  ) async {
    if (await repository.currentCountyCode() != null) return false;
    final gpsCounty = fix == null
        ? null
        : CountyBoundaryResolver.countyCodeFor(
            latitude: fix.latitude,
            longitude: fix.longitude,
            minimumInsideDistanceMeters:
                CountyBoundaryResolver.boundaryHysteresisMeters,
          );
    final county = gpsCounty ?? homeCountyCode;
    if (county == null) return false;
    await repository.seedCurrentCounty(county);
    final geofences = ref.read(geofenceServiceProvider);
    await geofences.initialize();
    await geofences.registerWindowFor(
      county,
      triggerEnterImmediately: gpsCounty == null || gpsCounty == homeCountyCode,
    );
    _logger.info(
      'Detection bootstrapped in county $county (gps $gpsCounty, '
      'home $homeCountyCode).',
    );
    return true;
  }
}
