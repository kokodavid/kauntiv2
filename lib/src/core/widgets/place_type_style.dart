import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../domain/place_type.dart';

/// Icon and colours for a [PlaceType]. The icon names match
/// `place_types.icon` in the database.
extension PlaceTypeStyle on PlaceType {
  IconData get icon => switch (key) {
    'waterfall' => Icons.water_drop,
    'hike' => Icons.hiking,
    'mountain' => Icons.landscape,
    'viewpoint' => Icons.visibility,
    'beach' => Icons.beach_access,
    'island' => Icons.sailing,
    'marine_park' => Icons.scuba_diving,
    'lake' => Icons.water,
    'river' => Icons.kayaking,
    'hot_spring' => Icons.hot_tub,
    'park' => Icons.park,
    'conservancy' => Icons.pets,
    'forest' => Icons.forest,
    'cave' => Icons.terrain,
    'desert' => Icons.wb_sunny,
    'garden' => Icons.local_florist,
    'museum' => Icons.museum,
    'historic_site' => Icons.fort,
    'monument' => Icons.account_balance,
    'landmark' => Icons.tour,
    'cultural_site' => Icons.theater_comedy,
    'market' => Icons.storefront,
    'food' => Icons.restaurant,
    'stay' => Icons.hotel,
    _ => Icons.place,
  };

  /// Map pin colour, by family.
  Color get pinColor => family.pinColor;

  /// The small dot on Place Detail's type pill: heritage and museums get
  /// the heritage purple, everything else the muted fallback (v1 parity).
  Color get dotColor => switch (family) {
    PlaceTypeFamily.heritage ||
    PlaceTypeFamily.museum => AppColors.categoryHeritageDot,
    _ => AppColors.categoryDotFallback,
  };
}

extension PlaceTypeFamilyStyle on PlaceTypeFamily {
  Color get pinColor => switch (this) {
    PlaceTypeFamily.nature || PlaceTypeFamily.wildlife => AppColors.placePark,
    PlaceTypeFamily.water || PlaceTypeFamily.coast => AppColors.placeShore,
    PlaceTypeFamily.heritage => AppColors.placeHeritage,
    PlaceTypeFamily.museum => AppColors.placeMuseum,
    PlaceTypeFamily.culture => AppColors.placeCulture,
    PlaceTypeFamily.food ||
    PlaceTypeFamily.stay ||
    PlaceTypeFamily.other => AppColors.placeOther,
  };
}
