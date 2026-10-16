import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/discover/domain/county_detail.dart';

void main() {
  test('slideshow leads with the county photo and skips duplicates', () {
    CountyDetailPlace place(String id, String? url) => CountyDetailPlace(
      id: id,
      title: id,
      description: '',
      category: PlaceType.park,
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
