import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/app_feature_flags.dart';
import '../../../core/services/app_config_provider.dart';
import '../../../core/services/location_diagnostics.dart';
import '../../auth/application/auth_providers.dart';
import '../../detection/application/detection_providers.dart';
import '../../detection/application/trip_fix_ingest.dart';
import '../data/device_journey_location_source.dart';
import '../data/fix_tapping_location_source.dart';
import '../data/journey_database.dart';
import '../data/local_journey_media_repository.dart';
import '../data/local_journey_repository.dart';
import '../data/platform_journey_settings_source.dart';
import '../domain/journey_fix.dart';
import 'journey_capture.dart';

part 'journey_providers.g.dart';

@Riverpod(keepAlive: true)
JourneyDatabase journeyDatabase(Ref ref) {
  final db = JourneyDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
LocalJourneyRepository localJourneyRepository(Ref ref) =>
    LocalJourneyRepository(ref.watch(journeyDatabaseProvider));

@Riverpod(keepAlive: true)
LocalJourneyMediaRepository localJourneyMediaRepository(Ref ref) =>
    LocalJourneyMediaRepository(ref.watch(journeyDatabaseProvider));

@Riverpod(keepAlive: true)
JourneyLocationSource journeyLocationSource(Ref ref) {
  // A recording Trip's fixes also tell county detection where the phone is,
  // at the fix's own time. Nothing extra is asked of the phone.
  final ingest = TripFixIngest(
    () => ref.read(detectionRepositoryProvider),
    isSignedIn: () => ref.read(currentUserIdProvider)() != null,
  );
  return FixTappingLocationSource(
    DeviceJourneyLocationSource(),
    (fix) => unawaited(
      ingest.offer(
        latitude: fix.latitude,
        longitude: fix.longitude,
        at: fix.recordedAt,
      ),
    ),
  );
}

@Riverpod(keepAlive: true)
JourneyCapture journeyCapture(Ref ref) => JourneyCapture(
  repository: ref.watch(localJourneyRepositoryProvider),
  locationSource: ref.watch(journeyLocationSourceProvider),
  // A Trip that loses location keeps recording and retrying for up to 15
  // minutes (power saving and weak signal often cut it for longer than a
  // few seconds) before pausing itself with a visible reason.
  streamRecoveryDelays: const [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ],
  maxRecoveryTime: const Duration(minutes: 15),
  deviceSettings: PlatformJourneySettingsSource(),
  onDiagnosticEvent:
      AppFeatureFlags.locationDiagnostics && ref.watch(appConfigProvider).isDev
      ? LocationDiagnostics.record
      : null,
);
