import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/public_trip_repository.dart';
import '../domain/public_trip_failure.dart';
import '../domain/public_trip_owner_view.dart';
import '../domain/public_trip_request_id.dart';
import '../domain/public_trip_share_preferences.dart';

part 'public_trip_providers.g.dart';

/// The public-trips repository, or null when the build has no Supabase.
@Riverpod(keepAlive: true)
PublicTripRepository? publicTripRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePublicTripRepository(client);
}

/// How often to look again while photos are being prepared. Overridden in
/// tests.
@riverpod
Duration publicTripPhotoPollInterval(Ref ref) => const Duration(seconds: 3);

/// Whether the owner may be offered "Make public": the server's publish
/// switch is on. Pro and suspension are still checked by the server when
/// preparing, so a refusal there is shown as its own message.
@riverpod
Future<bool> publicTripPublishingEnabled(Ref ref) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(publicTripRepositoryProvider);
  if (repository == null || ref.watch(currentUserIdProvider)() == null) {
    return false;
  }
  return repository.publishingEnabled();
}

/// This trip's public copy as its owner sees it, or null if it was never
/// made public.
@riverpod
Future<PublicTripOwnerView?> myPublicTrip(Ref ref, String journeyId) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(publicTripRepositoryProvider);
  if (repository == null) return null;
  return repository.mine(journeyId);
}

/// The owner's share defaults, saved optimistically.
@riverpod
class PublicTripSharePreferencesController
    extends _$PublicTripSharePreferencesController {
  @override
  Future<PublicTripSharePreferences> build() async {
    ref.watch(authUserIdProvider);
    final repository = ref.watch(publicTripRepositoryProvider);
    if (repository == null) return PublicTripSharePreferences.defaults;
    return repository.sharePreferences();
  }

  /// Saves [preferences]. The change shows at once and reverts, with the
  /// failure rethrown, if the server refuses it.
  Future<void> save(PublicTripSharePreferences preferences) async {
    final previous = state.value;
    state = AsyncData(preferences);
    final repository = ref.read(publicTripRepositoryProvider);
    if (repository == null) return;
    try {
      final saved = await repository.saveSharePreferences(preferences);
      if (ref.mounted) state = AsyncData(saved);
    } on Object {
      if (ref.mounted && previous != null) state = AsyncData(previous);
      rethrow;
    }
  }
}

/// Withdraws a trip's public copy. Each trip has its own state so the
/// confirm sheet can show progress and a failure.
@riverpod
class PublicTripWithdrawal extends _$PublicTripWithdrawal {
  @override
  AsyncValue<void> build(String journeyId) => const AsyncData(null);

  /// Takes the trip down for everyone, immediately. Throws
  /// [PublicTripFailure] if it could not be done.
  Future<void> withdraw(String publicationId) async {
    final repository = ref.read(publicTripRepositoryProvider);
    if (repository == null) {
      throw const PublicTripFailure('Public trips are not available here.');
    }
    state = const AsyncLoading();
    try {
      await repository.withdraw(
        publicationId: publicationId,
        requestId: newPublicTripRequestId(),
      );
      ref.invalidate(myPublicTripProvider(journeyId));
      if (ref.mounted) state = const AsyncData(null);
    } on PublicTripFailure catch (error) {
      if (ref.mounted) state = AsyncError(error, StackTrace.current);
      rethrow;
    }
  }
}
