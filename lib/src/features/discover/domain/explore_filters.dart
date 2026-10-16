import '../../../core/domain/place_type.dart';
import 'explore_entries.dart';

/// The Places filters: one place type plus the distance, county and claim
/// options, all picked in the filter sheet.
class ExploreFilters {
  const ExploreFilters({
    this.typeKey,
    this.typeKeys,
    this.typeKeysLabel,
    this.maxKm,
    this.unclaimedOnly = false,
    this.countyCode,
  });

  const ExploreFilters.none() : this();

  /// `places.type` key picked in the filter sheet, or null for "All".
  final String? typeKey;

  /// Several `places.type` keys at once, set by a "See all" on an interest
  /// chapter (which spans types). Cleared when a single type is picked.
  final Set<String>? typeKeys;

  /// What [typeKeys] stands for, shown on its removable pill ("Waterfalls
  /// and hikes").
  final String? typeKeysLabel;

  /// Furthest distance from the traveller, in km; null means any.
  final int? maxKm;
  final bool unclaimedOnly;
  final int? countyCode;

  /// The distances the filter sheet's slider stops on, before "Any".
  static const distanceStops = [25, 50, 100, 250];

  /// How many sheet options are on, not counting the single place type.
  int get sheetCount =>
      (typeKeys != null ? 1 : 0) +
      (maxKm != null ? 1 : 0) +
      (unclaimedOnly ? 1 : 0) +
      (countyCode != null ? 1 : 0);

  /// The place types that are on, whether set as one type or several.
  Set<String> get activeTypes => typeKeys ?? {?typeKey};

  /// These filters with exactly [keys] on: none clears the type, one sets
  /// [typeKey], several set [typeKeys] with a pill label ([label], or the
  /// first two type names and how many more, e.g. "Waterfalls, Lakes, +2").
  ExploreFilters withTypes(Set<String> keys, {String? label}) {
    if (keys.isEmpty) return copyWith(clearType: true);
    if (keys.length == 1) return copyWith(typeKey: keys.first);
    final ordered = [
      for (final type in PlaceType.all)
        if (keys.contains(type.key)) type,
    ];
    return copyWith(
      clearType: true,
      typeKeys: keys,
      typeKeysLabel:
          label ??
          [
            ...ordered.take(2).map((t) => t.pluralLabel),
            if (ordered.length > 2) '+${ordered.length - 2}',
          ].join(', '),
    );
  }

  /// Everything the filter button counts: the sheet options plus the
  /// single place type picked in the sheet's TYPE section.
  int get activeCount => sheetCount + (typeKey != null ? 1 : 0);

  bool get isEmpty => typeKey == null && typeKeys == null && sheetCount == 0;

  ExploreFilters copyWith({
    String? typeKey,
    bool clearType = false,
    Set<String>? typeKeys,
    String? typeKeysLabel,
    bool clearTypeKeys = false,
    int? maxKm,
    bool clearMaxKm = false,
    bool? unclaimedOnly,
    int? countyCode,
    bool clearCounty = false,
  }) => ExploreFilters(
    typeKey: clearType ? null : (typeKey ?? this.typeKey),
    typeKeys: clearTypeKeys || clearType || typeKey != null
        ? typeKeys
        : (typeKeys ?? this.typeKeys),
    typeKeysLabel: clearTypeKeys || clearType || typeKey != null
        ? typeKeysLabel
        : (typeKeysLabel ?? this.typeKeysLabel),
    maxKm: clearMaxKm ? null : (maxKm ?? this.maxKm),
    unclaimedOnly: unclaimedOnly ?? this.unclaimedOnly,
    countyCode: clearCounty ? null : (countyCode ?? this.countyCode),
  );

  bool matches(ExploreEntry entry) {
    if (typeKey != null && entry.place.category.key != typeKey) return false;
    if (typeKeys case final keys?
        when !keys.contains(entry.place.category.key)) {
      return false;
    }
    if (unclaimedOnly && entry.claimed) return false;
    if (countyCode != null && entry.countyCode != countyCode) return false;
    final limit = maxKm;
    if (limit != null) {
      final km = entry.km;
      if (km == null || km > limit) return false;
    }
    return true;
  }
}
