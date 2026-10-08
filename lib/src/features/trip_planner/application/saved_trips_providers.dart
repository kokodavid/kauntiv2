import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/saved_trips_repository.dart';
import '../domain/saved_trip.dart';

part 'saved_trips_providers.g.dart';

/// Null when this build has no Supabase.
@riverpod
SavedTripsRepository? savedTripsRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SavedTripsRepository(client);
}

/// The user's saved plans to a place, newest first. Empty when they cannot
/// be read: the list then simply does not show.
@riverpod
Future<List<SavedTrip>> savedTripsForPlace(Ref ref, String placeId) async {
  final repository = ref.watch(savedTripsRepositoryProvider);
  if (repository == null) return const [];
  try {
    return await repository.forPlace(placeId);
  } on Object {
    return const [];
  }
}

/// All the user's saved plans, newest first, for Home and the saved plans
/// screen. Empty when they cannot be read.
@riverpod
Future<List<SavedTrip>> savedTripsAll(Ref ref) async {
  final repository = ref.watch(savedTripsRepositoryProvider);
  if (repository == null) return const [];
  try {
    return await repository.all();
  } on Object {
    return const [];
  }
}
