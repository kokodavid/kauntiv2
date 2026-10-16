import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/widgets/interest_icons.dart';

void main() {
  test('known names resolve, unknown or blank names get the default pin', () {
    expect(interestIconForName('hiking'), Icons.hiking);
    expect(interestIconForName(' Hiking '), Icons.hiking);
    expect(interestIconForName('not_an_icon'), fallbackInterestIcon);
    expect(interestIconForName(null), fallbackInterestIcon);
  });
}
