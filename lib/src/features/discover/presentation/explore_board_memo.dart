import '../domain/explore_board.dart';
import '../domain/explore_entries.dart';

/// Remembers the last [ExploreBoard.filtered] and [exploreEntries] results,
/// so a rebuild with the same board (and query) reuses them instead of
/// walking every place again.
class ExploreBoardMemo {
  ExploreBoard? _filteredFrom;
  String? _query;
  ExploreBoard? _filtered;

  ExploreBoard? _entriesFrom;
  List<ExploreEntry> _entries = const [];

  ExploreBoard filtered(ExploreBoard board, String query) {
    final cached = _filtered;
    if (cached != null && identical(_filteredFrom, board) && _query == query) {
      return cached;
    }
    _filteredFrom = board;
    _query = query;
    return _filtered = board.filtered(query);
  }

  List<ExploreEntry> entries(ExploreBoard board) {
    if (!identical(_entriesFrom, board)) {
      _entriesFrom = board;
      _entries = exploreEntries(board);
    }
    return _entries;
  }
}
