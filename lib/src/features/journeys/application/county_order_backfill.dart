import 'dart:isolate';

import '../data/journey_county_split_resolver.dart';
import '../data/supabase_journey_repository.dart';

/// What a backfill run did.
class CountyOrderBackfillResult {
  const CountyOrderBackfillResult({
    required this.updated,
    required this.failed,
  });

  final int updated;
  final int failed;
}

/// Works out, for each of the signed-in user's uploaded trips, the order
/// the route first entered each county (from the saved route points and
/// the boundaries bundled in the app) and saves it. Safe to run again.
Future<CountyOrderBackfillResult> backfillCountyOrder(
  SupabaseJourneyRepository repo, {
  void Function(int done, int total)? onProgress,
}) async {
  final trips = [
    for (final trip in await repo.history())
      if (trip.countyNames.isNotEmpty) trip.id,
  ];
  var updated = 0;
  var failed = 0;
  for (var i = 0; i < trips.length; i++) {
    try {
      final points = await repo.points(trips[i]);
      final order = await Isolate.run(
        () => splitJourneyCounties(points).keys.toList(),
      );
      await repo.setCountyOrder(trips[i], order);
      updated++;
    } on Object {
      failed++;
    }
    onProgress?.call(i + 1, trips.length);
  }
  return CountyOrderBackfillResult(updated: updated, failed: failed);
}
