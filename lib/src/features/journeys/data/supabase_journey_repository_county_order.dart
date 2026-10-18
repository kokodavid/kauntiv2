part of 'supabase_journey_repository.dart';

/// Saves the order a Journey crossed its counties (first entered first).
extension SupabaseJourneyCountyOrder on SupabaseJourneyRepository {
  Future<void> setCountyOrder(String journeyId, List<int> countyCodes) =>
      _client
          .rpc<Object?>(
            'set_journey_county_order',
            params: {'p_journey_id': journeyId, 'p_county_ids': countyCodes},
          )
          .timeout(SupabaseJourneyRepository._timeout);
}

/// Turns `journey_counties` rows into county names per Journey, in the
/// order the route crossed them. Rows without a saved position (older
/// trips) come last, by county code, so the order is at least stable.
abstract final class _JourneyCountyNames {
  static Map<String, List<String>> byJourney(List<Map<String, dynamic>> rows) {
    final namesByCode = {for (final c in CountyPaths.all) c.code: c.name};
    final grouped = <String, List<(int position, int code)>>{};
    for (final row in rows) {
      final journeyId = row['journey_id'] as String?;
      final code = (row['county_id'] as num?)?.toInt();
      if (journeyId == null || code == null || namesByCode[code] == null) {
        continue;
      }
      final position = (row['position'] as num?)?.toInt() ?? 1 << 20;
      (grouped[journeyId] ??= []).add((position, code));
    }
    return {
      for (final MapEntry(key: id, value: entries) in grouped.entries)
        id: [
          for (final (_, code) in entries..sort(_compare)) namesByCode[code]!,
        ],
    };
  }

  static int _compare((int, int) a, (int, int) b) =>
      a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2);
}
