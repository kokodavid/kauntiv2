import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/fail_fast.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../badges/application/badges_providers.dart';
import '../data/place_check_in_repository.dart';
import '../domain/check_in_outcome.dart';

part 'place_check_in_providers.g.dart';

/// Null when the build has no Supabase. Tests override it.
@riverpod
PlaceCheckInRepository? placeCheckInRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePlaceCheckInRepository(client);
}

/// Whether the card shows, and whether this place is already done today.
/// A failed read counts as off, so the card never appears when it can't be
/// trusted.
@riverpod
Future<PlaceCheckInStatus> placeCheckInStatus(Ref ref, String placeId) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(placeCheckInRepositoryProvider);
  if (repository == null) return const PlaceCheckInStatus();
  try {
    return await failFast(ref, () => repository.status(placeId));
  } on Object {
    return const PlaceCheckInStatus();
  }
}

/// Sends the check-in and refreshes what depends on it. State is the last
/// answer (null before the first tap); loading while the position is read.
@riverpod
class PlaceCheckInController extends _$PlaceCheckInController {
  @override
  Future<CheckInOutcome?> build(String placeId) async => null;

  Future<void> checkIn() async {
    if (state.isLoading) return;
    final repository = ref.read(placeCheckInRepositoryProvider);
    if (repository == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.checkIn(placeId));
    final outcome = state.value;
    if (outcome != null && outcome.counted) {
      ref
        ..invalidate(placeCheckInStatusProvider(placeId))
        ..invalidate(badgeCollectionProvider)
        ..invalidate(countyBadgeDetailProvider);
    }
  }
}
