import 'package:native_geofence/native_geofence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/services/location_diagnostics.dart';
import '../../../services/app_logger.dart';
import '../domain/visit_models.dart';
import '../domain/visit_rules.dart';
import 'arrival_notifier.dart';
import 'claim_notifier.dart';
import 'detection_heartbeat.dart';
import 'detection_repository.dart';
import 'local/detection_database.dart';
import 'trip_start_reminder_notifier.dart';
import 'visit_sync_queue.dart';

/// Runs in a fresh background isolate when the OS reports a geofence
/// crossing or dwell, even with the app closed. No providers: it opens
/// the local database, records the crossing (or re-checks dwell
/// candidates, Android only) and closes it. It also makes one
/// best-effort attempt to upload what's queued -- see [_bestEffortSync]
/// -- but never depends on that succeeding; the foreground cycle still
/// uploads and re-registers geofences regardless.
///
/// With a location in the event, the polygon lookup decides the county
/// (circles overlap near borders); the fix is used only for that and is
/// never stored (doc 05). Without one, each triggering geofence's county
/// is used as reported. Nothing is recorded until a signed-in owner is
/// bound (onboarding done, not signed out).
@pragma('vm:entry-point')
Future<void> geofenceCallbackDispatcher(GeofenceCallbackParams params) async {
  const logger = AppLogger.detection();
  await LocationDiagnostics.record('geofence_transition', {
    'kind': params.event.name,
    'geofence_count': params.geofences.length,
  });

  await const DetectionHeartbeat().markGeofence();
  final db = DetectionDatabase();
  final repository = DetectionRepository(
    db,
    rules: const VisitRules(VisitTimings.current),
  );
  try {
    if (await db.select(db.detectionOwner).getSingleOrNull() == null) return;

    if (params.event == GeofenceEvent.dwell) {
      // Android only (see geofence_service.dart): the OS itself timed the
      // stay, so just re-check every running candidate the normal way --
      // it may not even be this geofence's county (a neighbour's
      // candidate can also be due by now).
      await _resolveDwelling(repository);
    } else {
      final kind = params.event == GeofenceEvent.exit
          ? CrossingKind.exit
          : CrossingKind.enter;
      await _record(params, repository, kind);
      await _syncClaimNotifications(repository);
      if (kind == CrossingKind.enter) {
        await _notifyArrival(repository);
        await _remindToRecordTrip();
      }
    }
    await _bestEffortSync(db);
  } on Object catch (error, stackTrace) {
    logger.warning(
      'Geofence callback failed.',
      error: error,
      stackTrace: stackTrace,
    );
  } finally {
    await db.close();
  }
}

/// The OS reported the phone has been inside a geofence long enough:
/// resolve any candidate that has actually passed the dwell threshold.
Future<void> _resolveDwelling(DetectionRepository repository) async {
  const logger = AppLogger.detection();
  final resolved = await repository.checkStillActiveCandidates();
  for (final visit in resolved) {
    logger.info('Resolved $visit from a geofence dwell.');
  }
}

/// Uploads whatever is queued, right from this background isolate, so a
/// visit resolved here doesn't just sit waiting for the app to be
/// reopened. A fresh isolate has no Supabase session of its own, so this
/// restores it from the same persisted session the foreground app uses.
/// Any failure here -- no network, no stored session yet, Supabase not
/// configured for this build -- just leaves the queue for the next
/// foreground cycle; nothing here is required for correctness.
Future<void> _bestEffortSync(DetectionDatabase db) async {
  const logger = AppLogger.detection();
  try {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
    if (url.isEmpty || key.isEmpty) return;
    final supabase = await Supabase.initialize(url: url, publishableKey: key);
    final queue = VisitSyncQueue.supabase(db, supabase.client);
    await queue.drain();
  } on Object catch (error, stackTrace) {
    logger.warning(
      'Background visit sync skipped.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Records the crossing in the local database (see the dispatcher).
Future<void> _record(
  GeofenceCallbackParams params,
  DetectionRepository repository,
  CrossingKind kind,
) async {
  const logger = AppLogger.detection();
  final location = params.location;
  if (location != null) {
    final entered = await repository.reconcileCurrentLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (entered != null) {
      logger.info('Geofence fix moved the phone into county $entered.');
      return;
    }
    // The fix didn't change the current county (e.g. no county was set
    // yet): an ENTER still starts a candidate for the polygon county.
    final polygonCounty = CountyBoundaryResolver.countyCodeFor(
      latitude: location.latitude,
      longitude: location.longitude,
      minimumInsideDistanceMeters:
          CountyBoundaryResolver.boundaryHysteresisMeters,
    );
    if (polygonCounty != null && kind == CrossingKind.enter) {
      await repository.handleEvent(
        CountyCrossingEvent(
          countyCode: polygonCounty,
          kind: kind,
          occurredAt: DateTime.now(),
        ),
      );
    }
    return;
  }

  for (final geofence in params.geofences) {
    final code = int.tryParse(geofence.id);
    if (code == null) continue;
    final visit = await repository.handleEvent(
      CountyCrossingEvent(
        countyCode: code,
        kind: kind,
        occurredAt: DateTime.now(),
      ),
    );
    if (visit != null) {
      logger.info('Resolved $visit from a geofence ${kind.name}.');
    }
  }
}

/// Posts the arrival notification when a recorded crossing is due one. A
/// failure here must never undo the recording above.
Future<void> _notifyArrival(DetectionRepository repository) async {
  try {
    await LocationDiagnostics.record('arrival_notification', {
      'result': 'checking',
    });
    final notifier = ArrivalNotifier();
    await notifier.initialize();
    await notifier.notifyIfDue(await repository.activeArrivalCandidates());
  } on Object catch (error, stackTrace) {
    await LocationDiagnostics.record('arrival_notification', {
      'result': 'failed',
      'error': error.toString(),
    });
    const AppLogger.detection().warning(
      'Arrival notification failed.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// iOS only: keeps the "county claimed" notifications in step with the
/// candidates after a crossing. Needs the plugin initialised, so it
/// initialises it here (safe to repeat). Never undoes the recording.
Future<void> _syncClaimNotifications(DetectionRepository repository) async {
  try {
    await ArrivalNotifier().initialize();
    await ClaimNotifier().sync(await repository.activeArrivalCandidates());
  } on Object catch (error, stackTrace) {
    const AppLogger.detection().warning(
      'Claim notification sync failed.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// A county crossing means the person is moving: suggests recording a Trip
/// when none is. The notifier's rules decide (switch, eligibility, daily
/// cap); the plugin was initialised by the arrival notification above.
/// A failure here must never undo the recording above.
Future<void> _remindToRecordTrip() async {
  try {
    await TripStartReminderNotifier().postIfDue();
  } on Object catch (error, stackTrace) {
    const AppLogger.detection().warning(
      'Trip start reminder failed.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
