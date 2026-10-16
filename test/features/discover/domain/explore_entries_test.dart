import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_entries.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_lists.dart';

ExplorePlace _place(String id) => ExplorePlace(
  id: id,
  title: 'Place $id',
  description: '',
  category: PlaceType.park,
  saved: false,
);

ExploreBoard _board({
  required List<ExplorePlace> preview,
  List<ExplorePlace> all = const [],
}) => ExploreBoard(
  featuredUnlock: null,
  mine: const [],
  unclaimed: [
    ExploreUnclaimedCounty(
      county: CountyPaths.byCode[1]!,
      blurb: '',
      percentHaveBeen: null,
      placeCount: all.length,
      previewPlaces: preview,
      allPlaces: all,
    ),
  ],
  saved: const [],
);

void main() {
  test('entries cover every place in a county, not just the preview', () {
    final all = [for (var i = 0; i < 5; i++) _place('p$i')];
    final entries = exploreEntries(
      _board(preview: all.take(3).toList(), all: all),
    );
    expect(entries.map((e) => e.place.id), ['p0', 'p1', 'p2', 'p3', 'p4']);
  });

  test('a board built with previews only still lists them', () {
    final preview = [_place('a'), _place('b')];
    final entries = exploreEntries(_board(preview: preview));
    expect(entries.map((e) => e.place.id), ['a', 'b']);
  });

  test('search matches places beyond the preview', () {
    final all = [for (var i = 0; i < 5; i++) _place('p$i')];
    final board = _board(preview: all.take(3).toList(), all: all);
    expect(board.filtered('place p4').unclaimed, hasLength(1));
    expect(board.filtered('nothing like this').unclaimed, isEmpty);
  });
}
