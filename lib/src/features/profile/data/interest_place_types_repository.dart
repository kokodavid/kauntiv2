import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/interest_place_types.dart';

/// Reads the `interest_place_types` table (readable by any signed-in user).
class InterestPlaceTypesRepository {
  const InterestPlaceTypesRepository(this.client);

  final SupabaseClient client;

  static const _timeout = Duration(seconds: 8);

  Future<InterestPlaceTypes> fetch() async {
    List<Map<String, dynamic>> rows;
    try {
      rows = await client
          .from('interest_place_types')
          .select('interest_key, place_type, is_primary, county_scope')
          .timeout(_timeout);
    } on PostgrestException {
      // A database that has not run the interests migration yet.
      rows = await client
          .from('interest_place_types')
          .select('interest_key, place_type')
          .timeout(_timeout);
    }
    return InterestPlaceTypes.fromRows(rows);
  }
}
