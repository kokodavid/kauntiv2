import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/profile/data/interest_catalogue_repository.dart';

void main() {
  test('rows become interests ordered by sort_order', () {
    final list = InterestCatalogueRepository.parse([
      {'key': 'b', 'label': 'B', 'sort_order': 20, 'icon_name': 'hiking'},
      {'key': 'a', 'label': 'A', 'short_name': 'a-things', 'sort_order': 10},
      {'key': 'a', 'label': 'Duplicate', 'sort_order': 5},
      {'key': ' ', 'label': 'Blank'},
    ]);
    expect(list.map((i) => i.key), ['a', 'b']);
    expect(list.first.shortName, 'a-things');
    expect(list.last.iconName, 'hiking');
    expect(list.last.shortName, 'b');
  });

  test('a blank icon_url means no image', () {
    final list = InterestCatalogueRepository.parse([
      {'key': 'a', 'label': 'A', 'icon_url': '  '},
      {'key': 'b', 'label': 'B', 'icon_url': 'https://x/y.svg'},
    ]);
    expect(list.first.iconUrl, isNull);
    expect(list.last.iconUrl, 'https://x/y.svg');
  });
}
