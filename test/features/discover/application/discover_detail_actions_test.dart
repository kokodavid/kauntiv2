import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/discover/application/discover_detail_actions.dart';
import 'package:kaunti47_v2/src/features/discover/data/directions_launcher.dart';
import 'package:kaunti47_v2/src/features/discover/data/discover_detail_repository.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_detail.dart';
import 'package:kaunti47_v2/src/features/discover/domain/place_category.dart';
import 'package:kaunti47_v2/src/features/discover/domain/place_detail.dart';

class _FakeRepository implements DiscoverDetailRepository {
  final saves = <(String, bool)>[];

  @override
  Future<CountyDetailData> countyDetail(int countyCode) =>
      throw UnimplementedError();

  @override
  Future<PlaceDetailData> placeDetail(String placeId) async => PlaceDetailData(
    id: placeId,
    title: 'Fort Jesus',
    category: PlaceCategory.heritage,
    county: CountyPaths.byCode[1]!,
    description: '',
    images: const [],
    source: 'Wikidata',
    saved: false,
  );

  @override
  Future<void> setPlaceSaved({
    required int countyCode,
    required String placeId,
    required bool saved,
  }) async => saves.add((placeId, saved));
}

class _FakeDirections extends DirectionsLauncher {
  String? lastQuery;

  @override
  Future<bool> open({double? latitude, double? longitude, String? query}) {
    lastQuery = query;
    return Future.value(true);
  }
}

void main() {
  test('saving goes through the repository', () async {
    final repository = _FakeRepository();
    final actions = DiscoverDetailActions(repository: repository);
    await actions.setPlaceSaved(countyCode: 1, placeId: 'p1', saved: true);
    expect(repository.saves, [('p1', true)]);
  });

  test('directions without coordinates search by name, county, Kenya', () async {
    final directions = _FakeDirections();
    final actions = DiscoverDetailActions(
      repository: _FakeRepository(),
      directions: directions,
    );
    final place = await actions.placeDetail('p1');
    await actions.openDirections(place);
    expect(directions.lastQuery, 'Fort Jesus, Mombasa, Kenya');
  });
}
