import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_media_quota.dart';

void main() {
  const free = JourneyMediaLimit(maxPhotos: 25, isPro: false, proMaxPhotos: 50);
  const pro = JourneyMediaLimit(maxPhotos: 50, isPro: true, proMaxPhotos: 50);

  test('remaining and full', () {
    expect(free.remaining(20), 5);
    expect(free.remaining(30), 0);
    expect(free.isFull(25), isTrue);
    expect(free.isFull(24), isFalse);
    expect(free.usageLabel(12), '12 of 25');
  });

  test('photosThatFit trims to the slots left', () {
    expect(photosThatFit(free, used: 20, wanted: 8), 5);
    expect(photosThatFit(free, used: 25, wanted: 3), 0);
    expect(photosThatFit(pro, used: 20, wanted: 8), 8);
    expect(photosThatFit(null, used: 99, wanted: 8), 8);
  });

  test('full message differs by tier', () {
    expect(free.fullMessage, contains('upgrade to Pro for up to 50'));
    expect(pro.fullMessage, isNot(contains('upgrade')));
  });
}
