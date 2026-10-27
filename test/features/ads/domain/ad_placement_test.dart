import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/ads/domain/ad_placement.dart';

void main() {
  bool at(int index, int total) =>
      AdPlacement.afterRow(index: index, total: total);

  test('one ad after every fourth row', () {
    final hits = [
      for (var i = 0; i < 20; i++)
        if (at(i, 20)) i,
    ];
    expect(hits, [3, 7, 11, 15]);
  });

  test('short lists get none, and a list never ends on an ad', () {
    expect([for (var i = 0; i < 4; i++) at(i, 4)], everyElement(isFalse));
    expect(at(3, 4), isFalse);
    expect(at(3, 5), isTrue);
    expect(at(7, 8), isFalse);
  });

  test('a screen can set its own spacing', () {
    expect(AdPlacement.afterRow(index: 7, total: 20, every: 8), isTrue);
    expect(AdPlacement.afterRow(index: 3, total: 20, every: 8), isFalse);
    expect(AdPlacement.afterRow(index: 15, total: 16, every: 8), isFalse);
  });
}
