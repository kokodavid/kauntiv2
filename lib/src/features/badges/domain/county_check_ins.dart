/// What a traveller has verified in one county by checking in at places.
/// Counts only; the places themselves are read per county.
class CountyCheckIns {
  const CountyCheckIns({
    this.places = 0,
    this.categories = 0,
    this.visitDays = 0,
    this.placesTotal = 0,
  });

  static const none = CountyCheckIns();

  /// Distinct places checked in at, how many place types they cover, how
  /// many distinct days, and how many reviewed places the county has (a
  /// county with few places lowers its own targets).
  final int places;
  final int categories;
  final int visitDays;
  final int placesTotal;

  Map<String, Object> toJson() => {
    'places': places,
    'categories': categories,
    'visit_days': visitDays,
    'places_total': placesTotal,
  };

  static CountyCheckIns fromJson(Map<dynamic, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return CountyCheckIns(
      places: n('places'),
      categories: n('categories'),
      visitDays: n('visit_days'),
      placesTotal: n('places_total'),
    );
  }
}

/// Every county's check-ins, and whether the server has the feature on.
/// While it is off nobody can check in, so Bronze to Gold stay "Later".
class CheckInsOverview {
  const CheckInsOverview({this.live = false, this.byCounty = const {}});

  static const none = CheckInsOverview();

  final bool live;
  final Map<int, CountyCheckIns> byCounty;

  CountyCheckIns of(int countyCode) => byCounty[countyCode] ?? CountyCheckIns.none;

  Map<String, Object> toJson() => {
    'live': live,
    'counties': {
      for (final e in byCounty.entries) '${e.key}': e.value.toJson(),
    },
  };

  static CheckInsOverview fromJson(Object? raw) {
    if (raw is! Map) return none;
    final counties = raw['counties'];
    return CheckInsOverview(
      live: raw['live'] == true,
      byCounty: {
        if (counties is Map)
          for (final e in counties.entries)
            if (int.tryParse('${e.key}') != null && e.value is Map)
              int.parse('${e.key}'): CountyCheckIns.fromJson(e.value as Map),
      },
    );
  }
}
