import '../data/county_news_flag_repository.dart';
import '../data/county_safety_repository.dart';
import '../data/deckwatch_county_safety_repository.dart';
import '../data/directions_launcher.dart';
import '../data/discover_detail_repository.dart';
import '../domain/county_detail.dart';
import '../domain/county_incident_summary.dart';
import '../domain/county_safety_feed.dart';
import '../domain/place_detail.dart';

/// What County and Place Detail can load and do. A plain class for now,
/// like Map Home's loader; it moves to `@riverpod` providers with the rest
/// of the app in tracker #2.
class DiscoverDetailActions {
  const DiscoverDetailActions({
    required this.repository,
    required this.countyNewsFlags,
    this.directions = const DirectionsLauncher(),
    this.countySafety = const DeckwatchCountySafetyRepository(),
  });

  final DiscoverDetailRepository repository;
  final CountyNewsFlagRepository countyNewsFlags;
  final DirectionsLauncher directions;
  final CountySafetyRepository countySafety;

  Future<CountyDetailData> countyDetail(int countyCode) =>
      repository.countyDetail(countyCode);

  Future<CountySafetyFeed> countySafetyFeed({
    required String countyName,
    required DateTime now,
  }) => countySafety.loadCountyFeed(countyName: countyName, now: now);

  Future<CountyIncidentSummary> countySafetySummary({
    required String countySlug,
    int days = CountyIncidentSummary.defaultPeriodDays,
  }) => countySafety.loadCountySummary(countySlug: countySlug, days: days);

  Future<bool> isCountyNewsEnabled() => countyNewsFlags.isEnabled();

  Future<PlaceDetailData> placeDetail(String placeId) =>
      repository.placeDetail(placeId);

  Future<void> setPlaceSaved({
    required int countyCode,
    required String placeId,
    required bool saved,
  }) => repository.setPlaceSaved(
    countyCode: countyCode,
    placeId: placeId,
    saved: saved,
  );

  Future<bool> openDirections(PlaceDetailData place) => directions.open(
    latitude: place.latitude,
    longitude: place.longitude,
    query: '${place.title}, ${place.county.name}, Kenya',
  );

  Future<bool> openSafetySource(Uri uri) => directions.openExternal(uri);
}
