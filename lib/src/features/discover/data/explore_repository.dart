import '../domain/explore_board.dart';

/// Explore's board and Wishlist writes. Saving a single place goes
/// through `DiscoverDetailRepository.setPlaceSaved`, shared with the
/// detail pages.
abstract interface class ExploreRepository {
  Future<ExploreBoard> loadBoard();

  /// Saves or un-saves a county on its own (a `wishlist_items` row with
  /// no place), from UNCLAIMED's Save button.
  Future<void> setCountySaved({required int countyCode, required bool saved});

  /// Ticks a saved place as visited, or clears the tick. Places are
  /// ticked by hand: the app only knows which county you were in.
  Future<void> setPlaceTicked({required String placeId, required bool ticked});
}
