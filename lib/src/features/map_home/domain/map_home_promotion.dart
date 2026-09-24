import '../../../counties/county_paths.dart';
import 'map_home_stat_format.dart';

/// A paid place placement for Home's For You (`place_promotions`,
/// placement `for_you`). Always shown with its [disclosureLabel] (doc 04:
/// sponsored content must be labelled).
class MapHomePromotedPlace {
  const MapHomePromotedPlace({
    required this.placeId,
    required this.placeName,
    required this.county,
    required this.disclosureLabel,
    required this.sponsorName,
    this.summary,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.areaKm2,
    this.elevationM,
    this.visitDurationMinutes,
  });

  final String placeId;
  final String placeName;
  final CountyPath county;

  /// Normally "AD".
  final String disclosureLabel;
  final String sponsorName;
  final String? summary;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final double? areaKm2;
  final int? elevationM;
  final int? visitDurationMinutes;

  List<({String value, String label})> get stats => [
    if (areaKm2 case final area?)
      (value: MapHomeStatFormat.area(area), label: 'Area'),
    if (elevationM case final elevation?)
      (value: MapHomeStatFormat.elevation(elevation), label: 'Elevation'),
    if (visitDurationMinutes case final minutes?)
      (value: MapHomeStatFormat.duration(minutes), label: 'Duration'),
  ];

  /// Coordinates when the place has them, else its name and county.
  String get directionsQuery => latitude != null && longitude != null
      ? '$latitude,$longitude'
      : '$placeName, ${county.name} County, Kenya';
}
