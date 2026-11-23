import 'trip_plan.dart';

/// One suggestion from the start-point search: a real-world spot (an
/// address, a business, a landmark, a town) with its exact coordinates.
class PlanPlaceSuggestion {
  const PlanPlaceSuggestion({
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
  });

  /// "Total Energies Westlands", "Rosewood Lane 12".
  final String name;

  /// The rest of the address: "Westlands, Nairobi, Kenya".
  final String? address;
  final double lat;
  final double lng;

  /// The full line stored with the plan, so everyone sees the same spot.
  String get label =>
      address == null || address!.isEmpty ? name : '$name, $address';

  /// This suggestion as where Day 1 starts.
  PlanStart toStart() =>
      PlanStart(kind: PlanStartKind.point, label: label, lat: lat, lng: lng);
}
