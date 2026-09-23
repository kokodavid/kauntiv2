import '../../../counties/county_paths.dart';
import '../data/map_home_repository.dart';
import '../domain/map_home_models.dart';

class MapHomeBoardLoader {
  const MapHomeBoardLoader({this.repository = const MockMapHomeRepository()});

  final MockMapHomeRepository repository;

  MapHomeBoardData loadBoard({CountyPath? homeCounty}) {
    return repository.loadBoard(homeCounty: homeCounty);
  }
}
