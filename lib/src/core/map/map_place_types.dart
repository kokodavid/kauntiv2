import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../domain/place_type.dart';
import '../widgets/place_type_style.dart';

/// Pin colours, icons and the legend for the map's place layers.
abstract final class MapPlaceTypes {
  /// Pin colour per listed type key, for the map's colour match.
  static final known = <String, Color>{
    for (final type in PlaceType.all) type.key: type.pinColor,
  };

  /// The map legend: one row per pin colour.
  static const legend = <(String, Color)>[
    ('Nature', AppColors.placePark),
    ('Water and coast', AppColors.placeShore),
    ('History', AppColors.placeHeritage),
    ('Museums', AppColors.placeMuseum),
    ('Culture', AppColors.placeCulture),
    ('Other', AppColors.placeOther),
  ];

  static Color colorFor(String type) => PlaceType.of(type).pinColor;

  static IconData iconFor(String type) => PlaceType.of(type).icon;
}
