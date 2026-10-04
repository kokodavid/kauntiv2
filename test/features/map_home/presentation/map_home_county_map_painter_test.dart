import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/design/app_colors.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';
import 'package:kaunti47_v2/src/features/map_home/presentation/map_home_county_map_painter.dart';

void main() {
  test('an unvisited home county uses the Home colour', () {
    final style = MapHomeCountyStyle.forState(
      MapHomeCountyBadgeState.locked,
      isHome: true,
    );

    expect(style.fill, AppColors.legendHome);
  });

  test('a non-home locked county keeps the locked colour', () {
    final style = MapHomeCountyStyle.forState(MapHomeCountyBadgeState.locked);

    expect(style.fill, Colors.white);
  });
}
