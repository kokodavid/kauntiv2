import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/map_home/presentation/map_popup_layout.dart';

void main() {
  const phone = MapPopupLayout(
    screen: Size(390, 844),
    topInset: 110,
    bottomReserve: 120,
  );

  test('the card fits between the header and the nav', () {
    final rect = phone.cardRect(Offset(195, phone.anchorY));
    expect(rect.top, greaterThanOrEqualTo(110));
    expect(rect.bottom, lessThan(phone.anchorY));
    expect(phone.anchorY, lessThanOrEqualTo(844 - 120));
    expect(rect.width, 264);
  });

  test('a short screen shrinks the card, never below its minimum', () {
    const short = MapPopupLayout(
      screen: Size(360, 600),
      topInset: 100,
      bottomReserve: 110,
    );
    expect(short.bodyHeight, greaterThanOrEqualTo(200));
    expect(short.bodyHeight, lessThanOrEqualTo(268));
    expect(short.height, short.bodyHeight + MapPopupLayout.tail);
  });

  test(
    'near an edge the card stays on screen and the tail follows the pin',
    () {
      const anchor = Offset(20, 500);
      final rect = phone.cardRect(anchor);
      expect(rect.left, MapPopupLayout.margin);
      expect(phone.tailX(anchor), 36); // clamped inside the card's corner
      const far = Offset(380, 500);
      expect(phone.cardRect(far).right, 390 - MapPopupLayout.margin);
    },
  );

  test('camera padding puts the pin at the anchor', () {
    final padding = phone.cameraPadding;
    // The padded area's centre is (screen + top - bottom) / 2.
    final centre = (844 + padding.top - padding.bottom) / 2;
    expect(centre, closeTo(phone.anchorY, 0.001));
    expect(padding.top == 0 || padding.bottom == 0, isTrue);
  });
}
