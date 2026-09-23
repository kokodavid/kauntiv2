import '../../../counties/county_paths.dart';
import '../data/map_home_repository.dart';
import '../domain/map_home_models.dart';
import '../domain/map_place.dart';

class MapHomeBoardLoader {
  const MapHomeBoardLoader({this.repository = const MockMapHomeRepository()});

  final MapHomeRepository repository;

  Future<MapHomeBoardData> loadBoard({CountyPath? homeCounty}) {
    return repository.loadBoard(homeCounty: homeCounty);
  }

  Future<List<MapPlace>> loadMapPlaces() => repository.loadMapPlaces();
}
