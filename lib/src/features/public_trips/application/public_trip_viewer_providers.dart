import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/public_trip_viewer_repository.dart';
import '../domain/public_trip_failure.dart';
import '../domain/public_trip_report_reason.dart';
import '../domain/public_trip_view.dart';

part 'public_trip_viewer_providers.g.dart';

/// The viewer-side repository, or null when the build has no Supabase.
@Riverpod(keepAlive: true)
PublicTripViewerRepository? publicTripViewerRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePublicTripViewerRepository(client);
}

/// How often an open trip re-checks that it is still available. A withdrawn,
/// hidden or blocked trip must not stay on screen.
@riverpod
Duration publicTripAccessRecheckInterval(Ref ref) =>
    const Duration(seconds: 30);

/// Whether public trips are on for viewers. Signed-out and unknown both read
/// as off, so nothing is offered that might be refused.
@riverpod
Future<bool> publicTripReadingEnabled(Ref ref) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(publicTripViewerRepositoryProvider);
  if (repository == null || ref.watch(currentUserIdProvider)() == null) {
    return false;
  }
  return repository.readingEnabled();
}

/// Home's row: public trips near [countyCode]. Any failure is an empty row
/// rather than an error, because the row is a bonus on Home.
@riverpod
Future<List<PublicTripView>> publicTripsForYou(Ref ref, int countyCode) async {
  if (!await ref.watch(publicTripReadingEnabledProvider.future)) {
    return const [];
  }
  final repository = ref.watch(publicTripViewerRepositoryProvider);
  if (repository == null) return const [];
  try {
    return await repository.forYou(countyCode);
  } on PublicTripFailure {
    return const [];
  }
}

/// One live trip, or null when it is not available to this viewer.
@riverpod
Future<PublicTripView?> publicTrip(Ref ref, String publicationId) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(publicTripViewerRepositoryProvider);
  if (repository == null) return null;
  return repository.get(publicationId);
}

/// Photo links for a trip revision, keyed by photo ID. Kept per revision so
/// the periodic access check does not sign the photos again each time.
@riverpod
Future<Map<String, String>> publicTripPhotoUrls(
  Ref ref,
  String publicationId,
  int revision,
) async {
  final repository = ref.watch(publicTripViewerRepositoryProvider);
  final trip = ref.read(publicTripProvider(publicationId)).value;
  if (repository == null || trip == null || trip.revision != revision) {
    return const {};
  }
  return repository.photoUrls(trip);
}

/// Reports and blocks. Stateless: each call either completes or throws a
/// [PublicTripFailure] with a message fit to show.
@riverpod
class PublicTripViewerActions extends _$PublicTripViewerActions {
  @override
  void build() {}

  PublicTripViewerRepository _repository() =>
      ref.read(publicTripViewerRepositoryProvider) ??
      (throw const PublicTripFailure('Public trips are not available here.'));

  Future<void> report(
    String publicationId,
    PublicTripReportReason reason, {
    String? details,
  }) => _repository().report(
    publicationId: publicationId,
    reason: reason,
    details: details,
  );

  /// Blocks (or unblocks) the author of a trip. Everything they published
  /// disappears from this viewer's Home and links.
  Future<void> setAuthorBlocked(
    String publicationId,
    String authorId, {
    required bool blocked,
  }) async {
    await _repository().setAuthorBlocked(authorId, blocked: blocked);
    ref.invalidate(publicTripProvider(publicationId));
    ref.invalidate(publicTripsForYouProvider);
  }
}
