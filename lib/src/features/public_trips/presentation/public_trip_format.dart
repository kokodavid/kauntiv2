import 'package:flutter/material.dart';

import '../domain/public_trip_view.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

/// "4 Oct 2026" - the trip's calendar day, never a time.
String publicTripDateLabel(DateTime? date) {
  if (date == null) return '';
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// "12.4 km", or metres under a kilometre.
String publicTripDistanceLabel(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  return '${km >= 100 ? km.round() : km.toStringAsFixed(1)} km';
}

/// "Nyeri", "Nyeri and Kirinyaga", "Nyeri, Kirinyaga and Murang'a".
String publicTripCountyNames(PublicTripView trip) {
  final names = [
    for (final county in trip.counties)
      if (county.name.isNotEmpty) county.name,
  ];
  if (names.isEmpty) return '';
  if (names.length == 1) return names.first;
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

String publicTripCountyCountLabel(PublicTripView trip) {
  final count = trip.counties.length;
  return count == 1 ? '1 county' : '$count counties';
}

IconData publicTripModeIcon(PublicTripView trip) =>
    trip.isWalk ? Icons.directions_walk : Icons.directions_car_filled_outlined;

String publicTripModeLabel(PublicTripView trip) =>
    trip.isWalk ? 'Walk' : 'Drive';
