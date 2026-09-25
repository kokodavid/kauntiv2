import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/device_journey_location_source.dart';
import '../data/journey_database.dart';
import '../data/local_journey_repository.dart';
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
JourneyLocationSource journeyLocationSource(Ref ref) =>
    DeviceJourneyLocationSource();

@Riverpod(keepAlive: true)
JourneyCapture journeyCapture(Ref ref) => JourneyCapture(
  repository: ref.watch(localJourneyRepositoryProvider),
  locationSource: ref.watch(journeyLocationSourceProvider),
);
