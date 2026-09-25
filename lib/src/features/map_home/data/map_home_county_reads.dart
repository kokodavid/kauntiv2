import 'package:supabase_flutter/supabase_flutter.dart';

import 'map_home_for_you_reads.dart';

/// The extra county details the map's county preview shows (headquarters
/// and places on file), read on their own so an older database missing
/// either one never costs Home its board.
class MapHomeCountyReads {
  const MapHomeCountyReads(this.client, this.readOptional);

  final SupabaseClient client;
  final ReadOptional readOptional;

  static const _timeout = Duration(seconds: 8);

  /// County code → headquarters town (`counties.capital`).
  Future<Map<int, String>> headquarters() async {
    final rows = await readOptional<List<dynamic>>(
      () => client.from('counties').select('id, capital').timeout(_timeout),
      label: 'county headquarters',
    );
    return {
      for (final row in (rows ?? const []).whereType<Map<dynamic, dynamic>>())
        if (row['id'] is num && row['capital'] is String)
          (row['id'] as num).toInt(): row['capital'] as String,
    };
  }

  /// County code → names of its places, in the database's order.
  Future<Map<int, List<String>>> placeNames() async {
    final rows = await readOptional<List<dynamic>>(
      () => client.from('places').select('county_id, name').timeout(_timeout),
      label: 'county place names',
    );
    final names = <int, List<String>>{};
    for (final row in (rows ?? const []).whereType<Map<dynamic, dynamic>>()) {
      if (row['county_id'] is num && row['name'] is String) {
        names
            .putIfAbsent((row['county_id'] as num).toInt(), () => [])
            .add(row['name'] as String);
      }
    }
    return names;
  }
}
