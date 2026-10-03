import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/trip_stats.dart';

abstract interface class TripStatsRepository {
  Future<TripStats> fetch();
}

class SupabaseTripStatsRepository implements TripStatsRepository {
  const SupabaseTripStatsRepository(this.client);

  final SupabaseClient client;

  static const _timeout = Duration(seconds: 8);

  @override
  Future<TripStats> fetch() async {
    final rows = await client
        .rpc<List<dynamic>>('profile_trip_stats')
        .timeout(_timeout);
    if (rows.isEmpty) return TripStats.zero;
    final row = rows.first as Map<String, dynamic>;
    return TripStats(
      tripCount: (row['trip_count'] as num?)?.toInt() ?? 0,
      totalDistanceM: (row['total_distance_m'] as num?)?.toDouble() ?? 0,
      longestDistanceM: (row['longest_distance_m'] as num?)?.toDouble() ?? 0,
    );
  }
}
