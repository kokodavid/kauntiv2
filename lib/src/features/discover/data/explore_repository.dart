import '../domain/explore_board.dart';

/// Explore's board data. Saving a place goes through
/// `DiscoverDetailRepository.setPlaceSaved`, shared with the detail pages.
abstract interface class ExploreRepository {
  Future<ExploreBoard> loadBoard();
}
