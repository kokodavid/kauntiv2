import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/trip_stats_repository.dart';
import '../domain/trip_stats.dart';

part 'trip_stats_providers.g.dart';

@riverpod
TripStatsRepository? tripStatsRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseTripStatsRepository(client);
}

/// The signed-in account's Trip count / distance stats, for Profile's
/// progress card. Reloads when the account changes.
@riverpod
Future<TripStats> tripStats(Ref ref) async {
  ref.watch(authUserIdProvider);
  final userId = ref.watch(currentUserIdProvider)();
  final repository = ref.watch(tripStatsRepositoryProvider);
  if (userId == null || repository == null) return TripStats.zero;
  return repository.fetch();
}
