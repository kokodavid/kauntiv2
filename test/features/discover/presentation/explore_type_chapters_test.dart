import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_entries.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_interest_chapters.dart';

ExploreEntry _entry(String id, PlaceType type) => ExploreEntry(
  place: ExplorePlace(
    id: id,
    title: id,
    description: '',
    category: type,
    saved: false,
  ),
  countyCode: 1,
  countyName: 'County',
  claimed: false,
);

void main() {
  test('one chapter per type, the biggest first, capped at six cards', () {
    final chapters = exploreTypeChapters([
      for (var i = 0; i < 8; i++) _entry('w$i', PlaceType.waterfall),
      _entry('b0', PlaceType.beach),
      _entry('b1', PlaceType.beach),
      _entry('l0', PlaceType.lake),
    ]);
    expect(chapters.map((c) => c.type.key), ['waterfall', 'beach', 'lake']);
    expect(chapters.first.places, hasLength(6));
    expect(chapters.first.total, 8);
  });

  test('types already shown are left out', () {
    final chapters = exploreTypeChapters(
      [
        _entry('w0', PlaceType.waterfall),
        _entry('b0', PlaceType.beach),
        _entry('l0', PlaceType.lake),
      ],
      exclude: {'waterfall', 'beach'},
    );
    expect(chapters.map((c) => c.type.key), ['lake']);
  });
}
