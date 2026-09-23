import '../domain/county_detail.dart';
import '../domain/place_detail.dart';

abstract interface class DiscoverDetailRepository {
  Future<CountyDetailData> countyDetail(int countyCode);

  Future<PlaceDetailData> placeDetail(String placeId);

  /// Saves or un-saves a place on the traveller's wishlist.
  Future<void> setPlaceSaved({
    required int countyCode,
    required String placeId,
    required bool saved,
  });
}
