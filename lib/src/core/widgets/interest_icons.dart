import 'package:flutter/material.dart';

/// Icons an admin can pick by name for an interest (`interests.icon_name`).
/// A name the app does not know shows [fallbackInterestIcon]; a brand-new
/// look needs an uploaded image (`icon_url`) or an app update.
const Map<String, IconData> interestIconNames = {
  'park': Icons.park_outlined,
  'forest': Icons.forest_outlined,
  'terrain': Icons.terrain,
  'landscape': Icons.landscape_outlined,
  'water_drop': Icons.water_drop_outlined,
  'waves': Icons.waves,
  'kayaking': Icons.kayaking,
  'sailing': Icons.sailing,
  'hiking': Icons.hiking,
  'directions_walk': Icons.directions_walk,
  'pedal_bike': Icons.pedal_bike,
  'camping': Icons.holiday_village_outlined,
  'beach_access': Icons.beach_access_outlined,
  'hot_tub': Icons.hot_tub_outlined,
  'museum': Icons.museum_outlined,
  'account_balance': Icons.account_balance_outlined,
  'theater_comedy': Icons.theater_comedy_outlined,
  'pets': Icons.pets_outlined,
  'restaurant': Icons.restaurant_outlined,
  'local_cafe': Icons.local_cafe_outlined,
  'storefront': Icons.storefront_outlined,
  'visibility': Icons.visibility_outlined,
  'photo_camera': Icons.photo_camera_outlined,
  'spa': Icons.spa_outlined,
  'hotel': Icons.hotel_outlined,
  'local_florist': Icons.local_florist_outlined,
  'wb_sunny': Icons.wb_sunny_outlined,
  'music_note': Icons.music_note_outlined,
  'sports_soccer': Icons.sports_soccer_outlined,
  'directions_boat': Icons.directions_boat_outlined,
  'flight': Icons.flight_outlined,
  'star': Icons.star_outline,
  'favorite': Icons.favorite_border,
  'place': Icons.place_outlined,
};

const fallbackInterestIcon = Icons.place_outlined;

/// The icon for an `interests.icon_name`, or [fallbackInterestIcon].
IconData interestIconForName(String? name) =>
    interestIconNames[name?.trim().toLowerCase()] ?? fallbackInterestIcon;
