import 'package:kaunti47_v2/src/features/public_trips/data/public_trip_viewer_repository.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_failure.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_owner_view.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_report_reason.dart';
import 'package:kaunti47_v2/src/features/public_trips/domain/public_trip_view.dart';

PublicTripView viewerTrip({
  String id = 'pub-1',
  String title = 'Naivasha loop',
  int revision = 1,
  int unclaimed = 0,
  String authorName = 'Wanjiru',
  int photos = 0,
}) => PublicTripView(
  id: id,
  revision: revision,
  title: title,
  author: PublicTripAuthor(
    id: 'author-1',
    displayName: authorName,
    handle: 'wanjiru',
  ),
  tripDate: DateTime.utc(2026, 9, 25),
  transportMode: 'drive',
  distanceMeters: 12400,
  counties: const [
    PublicTripCounty(code: 47, name: 'Nairobi'),
    PublicTripCounty(code: 32, name: 'Nakuru'),
  ],
  routeLines: const [
    [PublicTripPoint(-1.30, 36.82), PublicTripPoint(-1.29, 36.83)],
  ],
  photos: [for (var i = 0; i < photos; i++) PublicTripPhoto(id: 'ph-$i')],
  unclaimedCounties: unclaimed,
);

/// An in-memory viewer repository for tests.
class FakePublicTripViewerRepository implements PublicTripViewerRepository {
  bool enabled = true;
  PublicTripView? trip;
  List<PublicTripView> forYouTrips = const [];
  PublicTripFailure? failure;
  Map<String, String> urls = const {};

  final reports = <({String id, PublicTripReportReason reason})>[];
  final blocks = <({String authorId, bool blocked})>[];
  var getCalls = 0;

  @override
  Future<bool> readingEnabled() async => enabled;

  @override
  Future<List<PublicTripView>> forYou(int countyCode, {int limit = 10}) async {
    final error = failure;
    if (error != null) throw error;
    return forYouTrips;
  }

  @override
  Future<PublicTripView?> get(String publicationId) async {
    getCalls++;
    final error = failure;
    if (error != null) throw error;
    return trip;
  }

  @override
  Future<Map<String, String>> photoUrls(PublicTripView trip) async => urls;

  @override
  Future<void> report({
    required String publicationId,
    required PublicTripReportReason reason,
    String? details,
  }) async {
    final error = failure;
    if (error != null) throw error;
    reports.add((id: publicationId, reason: reason));
  }

  @override
  Future<void> setAuthorBlocked(
    String authorId, {
    required bool blocked,
  }) async {
    blocks.add((authorId: authorId, blocked: blocked));
  }
}
