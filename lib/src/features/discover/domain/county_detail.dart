import '../../../counties/county_paths.dart';
import 'place_category.dart';

/// Static facts about a county. Nulls mean "not on file yet" and are
/// shown as such, never guessed.
class CountyQuickFacts {
  const CountyQuickFacts({
    this.yearEstablished,
    this.population,
    this.areaKm2,
    this.elevationM,
    this.governorName,
  });

  final int? yearEstablished;
  final int? population;
  final num? areaKm2;
  final num? elevationM;
  final String? governorName;
}

/// A place row on County Detail's "Places to See" list.
class CountyDetailPlace {
  const CountyDetailPlace({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.saved,
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String description;
  final PlaceCategory category;
  final bool saved;
  final String? thumbnailUrl;
}

class CountyDetailData {
  const CountyDetailData({
    required this.county,
    required this.aboutBlurb,
    required this.quickFacts,
    required this.places,
    required this.personalStatusLabel,
    required this.isHeld,
    this.highlightImageUrl,
  });

  final CountyPath county;
  final String aboutBlurb;
  final CountyQuickFacts quickFacts;
  final List<CountyDetailPlace> places;

  /// The traveller's own standing: "NOT VISITED YET", "PASSED THROUGH 2
  /// TIMES", "EXPLORED" or "LOCAL EXPERT".
  final String personalStatusLabel;

  /// Explored (held) by the traveller.
  final bool isHeld;
  final String? highlightImageUrl;

  /// County photo first, then place photos, without duplicates.
  List<String> get slideshowImages => [
    ?highlightImageUrl,
    for (final place in places)
      if (place.thumbnailUrl case final url?)
        if (url != highlightImageUrl) url,
  ];
}
