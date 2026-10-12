import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/interest_place_types.dart';

/// Reads the `interest_place_types` table (readable by any signed-in user).
class InterestPlaceTypesRepository {
  const InterestPlaceTypesRepository(this.client);

  final SupabaseClient client;

  Future<InterestPlaceTypes> fetch() async {
    final rows = await client
        .from('interest_place_types')
        .select('interest_key, place_type')
        .timeout(const Duration(seconds: 8));
    return InterestPlaceTypes.fromRows(rows);
  }
}
