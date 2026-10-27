import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/ads/domain/ad_units.dart';

void main() {
  test('dev builds always get Google test units', () {
    expect(
      AdUnits.native(isIos: false, prod: false),
      startsWith('ca-app-pub-3940256099942544/'),
    );
    expect(
      AdUnits.native(isIos: true, prod: false),
      startsWith('ca-app-pub-3940256099942544/'),
    );
  });

  test('prod has no unit until a real one is added, so no ad is requested', () {
    expect(AdUnits.native(isIos: false, prod: true), isNull);
    expect(AdUnits.native(isIos: true, prod: true), isNull);
  });
}
