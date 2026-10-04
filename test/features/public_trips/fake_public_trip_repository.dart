import 'package:kaunti47_v2/src/features/public_trips/data/public_trip_repository.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_failure.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_owner_view.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_share_preferences.dart';

PublicTripOwnerView ownerView({
  PublicTripStatus status = PublicTripStatus.prepared,
  int revision = 1,
  int photosPending = 0,
  int photosFailed = 0,
  int? activeRevision,
  bool hidden = false,
  String? reviewReason,
}) => PublicTripOwnerView(
  id: 'pub-1',
  status: status,
  revision: revision,
  title: 'Morning drive',
  tripDate: DateTime.utc(2026, 9, 25),
  transportMode: 'drive',
  distanceMeters: 12400,
  counties: const [PublicTripCounty(code: 47, name: 'Nairobi')],
  routeLines: const [
    [PublicTripPoint(-1.30, 36.82), PublicTripPoint(-1.29, 36.83)],
  ],
  photosPending: photosPending,
  photosFailed: photosFailed,
  contentHash: 'hash-$revision',
  activeRevision: activeRevision,
  hidden: hidden,
  reviewReason: reviewReason,
);

/// An in-memory repository for tests.
class FakePublicTripRepository implements PublicTripRepository {
  bool enabled = true;
  PublicTripOwnerView? mineView;
  PublicTripOwnerView prepareResult = ownerView();
  PublicTripFailure? prepareFailure;
  PublicTripFailure? submitFailure;
  PublicTripSharePreferences preferences = PublicTripSharePreferences.defaults;

  final prepareCalls = <Map<String, Object?>>[];
  final submitCalls = <String>[];
  final withdrawCalls = <String>[];
  final savedPreferences = <PublicTripSharePreferences>[];

  @override
  Future<bool> publishingEnabled() async => enabled;

  @override
  Future<PublicTripOwnerView?> mine(String journeyId) async => mineView;

  @override
  Future<PublicTripOwnerView> prepare({
    required String journeyId,
    required String requestId,
    required String title,
    required List<PublicTripMomentChoice> moments,
    required List<String> photoIds,
    required int startTrimMeters,
    required int endTrimMeters,
  }) async {
    prepareCalls.add({
      'requestId': requestId,
      'title': title,
      'moments': moments,
      'photoIds': photoIds,
      'trim': startTrimMeters,
    });
    final failure = prepareFailure;
    if (failure != null) throw failure;
    return prepareResult;
  }

  @override
  Future<PublicTripOwnerView> submit({
    required String publicationId,
    required int revision,
    required String contentHash,
  }) async {
    submitCalls.add(contentHash);
    final failure = submitFailure;
    if (failure != null) throw failure;
    return ownerView(status: PublicTripStatus.submitted, revision: revision);
  }

  @override
  Future<void> withdraw({
    required String publicationId,
    required String requestId,
  }) async => withdrawCalls.add(publicationId);

  @override
  Future<PublicTripSharePreferences> sharePreferences() async => preferences;

  @override
  Future<PublicTripSharePreferences> saveSharePreferences(
    PublicTripSharePreferences next,
  ) async {
    savedPreferences.add(next);
    preferences = next;
    return next;
  }
}
