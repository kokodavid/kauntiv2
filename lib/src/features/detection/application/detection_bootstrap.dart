import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/services/app_current_location.dart';
import '../../../services/app_logger.dart';
import '../data/detection_repository.dart';
import '../data/geofence_service.dart';

/// First run after onboarding: the phone's county comes from the fix (the
/// home county is a preference, not where the phone is), falling back to the
/// home county. The OS is asked to report an ENTER for the county the phone
/// is already in, unless the fix shows it's elsewhere.
class DetectionBootstrap {
  const DetectionBootstrap({required this.repository, required this.geofences});

  static const _logger = AppLogger.detection();

  final DetectionRepository repository;
  final GeofenceService geofences;

  /// True when this run seeded the current county.
  Future<bool> run(
    AppLocationReading? fix,
    int? homeCountyCode, {
    required bool registerGeofences,
  }) async {
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
    if (!registerGeofences) return true;
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
