import '../data/directions_launcher.dart';
import '../data/discover_detail_repository.dart';
import '../domain/county_detail.dart';
import '../domain/place_detail.dart';

/// What County and Place Detail can load and do. A plain class for now,
/// like Map Home's loader; it moves to `@riverpod` providers with the rest
/// of the app in tracker #2.
class DiscoverDetailActions {
  const DiscoverDetailActions({
    required this.repository,
    this.directions = const DirectionsLauncher(),
  });

  final DiscoverDetailRepository repository;
  final DirectionsLauncher directions;

  Future<CountyDetailData> countyDetail(int countyCode) =>
      repository.countyDetail(countyCode);

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
}
