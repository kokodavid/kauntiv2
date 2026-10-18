import '../../../core/domain/place_type.dart';
import '../../../counties/county_paths.dart';

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
    this.imageCredits = const [],
    this.imageAspects = const [],
    this.acceptsPhotos = true,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String title;
  final PlaceType category;
  final CountyPath county;
  final String description;
  final List<String> images;

  /// "@username" for each of [images] that a user took, else null; the same
  /// length as [images] (or empty when none is credited).
  final List<String?> imageCredits;

  /// Width / height of each of [images] where the database knows it, else
  /// null; the gallery uses it to give every photo its own shape.
  final List<double?> imageAspects;

  /// Whether people can send photos for this place: only reviewed places
  /// that are not archived (the database enforces the same rule).
  final bool acceptsPhotos;
  final String source;
  final bool saved;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
}
