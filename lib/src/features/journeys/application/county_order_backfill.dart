import 'dart:isolate';

import '../data/journey_county_split_resolver.dart';
import '../data/supabase_journey_repository.dart';

/// Works out, for the signed-in user's trips that have no saved county
/// order, the order the route first entered each county (from the saved
/// route points and the boundaries bundled in the app) and saves it.
///
/// Runs on the phone because the county boundaries are only in the app.
/// Does at most [limit] trips per call; the rest are picked up next launch.
/// A trip that fails is skipped and tried again next time. Returns how many
/// trips were updated.
Future<int> backfillCountyOrder(
  SupabaseJourneyRepository repo, {
  int limit = 25,
  bool Function()? shouldStop,
}) async {
  var updated = 0;
  for (final id in await repo.tripsMissingCountyOrder(limit: limit)) {
    if (shouldStop?.call() ?? false) break;
    try {
      final points = await repo.points(id);
      final order = await Isolate.run(
        () => splitJourneyCounties(points).keys.toList(),
      );
      await repo.setCountyOrder(id, order);
      updated++;
    } on Object {
      continue;
    }
  }
  return updated;
}
