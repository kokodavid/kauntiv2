import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/saved_trip.dart';

/// The signed-in user's saved trip plans (`saved_trips`; row-level security
/// keeps each user to their own).
class SavedTripsRepository {
  const SavedTripsRepository(this.client);

  final SupabaseClient client;

  static const _columns =
      'id, name, destination_place_id, stop_place_ids, custom_order';
  static const _timeout = Duration(seconds: 8);

  Future<List<SavedTrip>> forPlace(String destinationPlaceId) async {
    final rows = await client
        .from('saved_trips')
        .select(_columns)
        .eq('destination_place_id', destinationPlaceId)
        .order('created_at', ascending: false)
        .timeout(_timeout);
    return [for (final row in rows) ?SavedTrip.fromRow(row)];
  }

  /// Every plan, newest first (the insert policy caps them at 50).
  Future<List<SavedTrip>> all() async {
    final rows = await client
        .from('saved_trips')
        .select(_columns)
        .order('created_at', ascending: false)
        .limit(50)
        .timeout(_timeout);
    return [for (final row in rows) ?SavedTrip.fromRow(row)];
  }

  Future<SavedTrip> save({
    required String name,
    required String destinationPlaceId,
    required List<String> stopPlaceIds,
    required bool customOrder,
  }) async {
    try {
      final row = await client
          .from('saved_trips')
          .insert({
            'name': name.trim(),
            'destination_place_id': destinationPlaceId,
            'stop_place_ids': stopPlaceIds,
            'custom_order': customOrder,
          })
          .select(_columns)
          .single()
          .timeout(_timeout);
      return SavedTrip.fromRow(row)!;
    } on PostgrestException catch (error) {
      // 23505: unique plan; 42501: the 50-trip limit in the insert policy.
      if (error.code == '23505') throw const SavedTripExists();
      if (error.code == '42501') throw const SavedTripsFull();
      rethrow;
    }
  }

  Future<void> rename(String id, String name) => client
      .from('saved_trips')
      .update({
        'name': name.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', id)
      .timeout(_timeout);

  Future<void> delete(String id) =>
      client.from('saved_trips').delete().eq('id', id).timeout(_timeout);
}
