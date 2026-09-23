import '../../../counties/county_paths.dart';
import 'place_category.dart';

class PlaceDetailData {
  const PlaceDetailData({
    required this.id,
    required this.title,
    required this.category,
    required this.county,
    required this.description,
    required this.images,
    required this.source,
    required this.saved,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String title;
  final PlaceCategory category;
  final CountyPath county;
  final String description;
  final List<String> images;
  final String source;
  final bool saved;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
}
