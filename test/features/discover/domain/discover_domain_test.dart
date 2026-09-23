import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_detail.dart';
import 'package:kaunti47_v2/src/features/discover/domain/place_category.dart';

void main() {
  test('place types map to categories; museums read as heritage', () {
    expect(PlaceCategory.fromType('park'), PlaceCategory.park);
    expect(PlaceCategory.fromType('museum'), PlaceCategory.heritage);
    expect(PlaceCategory.fromType('something-new'), PlaceCategory.culture);
  });

  test('slideshow leads with the county photo and skips duplicates', () {
    CountyDetailPlace place(String id, String? url) => CountyDetailPlace(
      id: id,
      title: id,
      description: '',
      category: PlaceCategory.park,
      saved: false,
      thumbnailUrl: url,
    );
    final data = CountyDetailData(
      county: CountyPaths.byCode[47]!,
      aboutBlurb: '',
      quickFacts: const CountyQuickFacts(),
      places: [place('a', 'county.jpg'), place('b', 'b.jpg'), place('c', null)],
      personalStatusLabel: 'EXPLORED',
      isHeld: true,
      highlightImageUrl: 'county.jpg',
    );
    expect(data.slideshowImages, ['county.jpg', 'b.jpg']);
  });
}
