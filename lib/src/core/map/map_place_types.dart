import 'package:flutter/material.dart';

import '../../design/app_colors.dart';

/// Pin colour and label per place type, shared by the map layers, the
/// legend and the place sheet.
abstract final class MapPlaceTypes {
  static const known = <String, (String, Color)>{
    'park': ('Parks', AppColors.placePark),
    'museum': ('Museums', AppColors.placeMuseum),
    'culture': ('Culture', AppColors.placeCulture),
    'heritage': ('Heritage', AppColors.placeHeritage),
    'shore': ('Shores', AppColors.placeShore),
  };

  static Color colorFor(String type) => known[type]?.$2 ?? AppColors.placeOther;

  static IconData iconFor(String type) => switch (type) {
    'park' => Icons.forest,
    'museum' => Icons.museum,
    'culture' => Icons.theater_comedy,
    'heritage' => Icons.account_balance,
    'shore' => Icons.beach_access,
    _ => Icons.place,
  };
}
