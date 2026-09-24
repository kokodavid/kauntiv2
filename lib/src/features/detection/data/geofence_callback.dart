import 'package:native_geofence/native_geofence.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../services/app_logger.dart';
import '../domain/visit_models.dart';
import '../domain/visit_rules.dart';
import 'detection_repository.dart';
import 'local/detection_database.dart';

/// Runs in a fresh background isolate when the OS reports a geofence
/// crossing, even with the app closed. No providers, no network: it opens
/// the local database, records the crossing and closes it. The foreground
/// cycle uploads and re-registers later.
///
/// With a location in the event, the polygon lookup decides the county
/// (circles overlap near borders); the fix is used only for that and is
/// never stored (doc 05). Without one, each triggering geofence's county
/// is used as reported. Nothing is recorded until a signed-in owner is
/// bound (onboarding done, not signed out).
@pragma('vm:entry-point')
Future<void> geofenceCallbackDispatcher(GeofenceCallbackParams params) async {
  const logger = AppLogger.detection();
  if (params.event == GeofenceEvent.dwell) return;
  final kind = params.event == GeofenceEvent.exit
      ? CrossingKind.exit
      : CrossingKind.enter;

  final db = DetectionDatabase();
  final repository = DetectionRepository(
    db,
    rules: const VisitRules(VisitTimings.current),
  );
  try {
    if (await db.select(db.detectionOwner).getSingleOrNull() == null) return;

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
