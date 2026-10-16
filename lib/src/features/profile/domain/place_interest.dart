/// A kind of place a traveller can say they like (setup step 2 and
/// Settings > Interests). [key] is what is stored on `profiles.interests`.
///
/// The list lives in the `interests` table, so an admin can add or rename
/// one without an app release; the built-in set below is the offline and
/// first-launch fallback, and the keys the tests use. Two interests are
/// equal when their keys are.
class PlaceInterest {
  const PlaceInterest(
    this.key,
    this.label,
    this.shortName, {
    this.iconName = 'place',
    this.iconUrl,
    this.sortOrder = 100,
  });

  /// A row of the `interests` table.
  factory PlaceInterest.fromRow(Map<dynamic, dynamic> row) {
    final key = '${row['key']}';
    final label = '${row['label'] ?? key}';
    final short = row['short_name'] as String?;
    final url = (row['icon_url'] as String?)?.trim();
    return PlaceInterest(
      key,
      label,
      (short == null || short.trim().isEmpty) ? label.toLowerCase() : short,
      iconName: (row['icon_name'] as String?) ?? 'place',
      iconUrl: (url == null || url.isEmpty) ? null : url,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 100,
    );
  }

  /// A saved key the catalogue has not told us about (yet). Keeps the pick
  /// so it is not lost; screens swap it for the catalogue entry when known.
  const PlaceInterest.unlisted(String key)
    : this(key, key, key, sortOrder: 1000);

  final String key;
  final String label;

  /// Lower-case noun used in a sentence ("find waterfalls near you").
  final String shortName;

  /// Looked up in the app's icon list (`interestIconForName`).
  final String iconName;

  /// Optional image (SVG or PNG); shown instead of [iconName] when set.
  final String? iconUrl;
  final int sortOrder;

  static const nature = PlaceInterest(
    'nature',
    'Nature and parks',
    'parks',
    iconName: 'park',
    sortOrder: 10,
  );
  static const water = PlaceInterest(
    'water',
    'Lakes, rivers and waterfalls',
    'lakes and waterfalls',
    iconName: 'water_drop',
    sortOrder: 20,
  );
  static const activities = PlaceInterest(
    'activities',
    'Hikes and activities',
    'hikes',
    iconName: 'hiking',
    sortOrder: 30,
  );
  static const coast = PlaceInterest(
    'coast',
    'Beaches and coast',
    'coast',
    iconName: 'beach_access',
    sortOrder: 40,
  );
  static const culture = PlaceInterest(
    'culture',
    'Culture and history',
    'heritage sites',
    iconName: 'museum',
    sortOrder: 50,
  );
  static const wild = PlaceInterest(
    'wild',
    'Wildlife',
    'wildlife',
    iconName: 'pets',
    sortOrder: 60,
  );
  static const food = PlaceInterest(
    'food',
    'Food and markets',
    'markets',
    iconName: 'restaurant',
    sortOrder: 70,
  );
  static const views = PlaceInterest(
    'views',
    'Views and viewpoints',
    'viewpoints',
    iconName: 'visibility',
    sortOrder: 80,
  );
  static const relax = PlaceInterest(
    'relax',
    'Relaxing spots',
    'quiet spots',
    iconName: 'spa',
    sortOrder: 90,
  );

  /// The built-in set, in display order: the fallback when the catalogue
  /// has not loaded.
  static const values = [
    nature,
    water,
    activities,
    coast,
    culture,
    wild,
    food,
    views,
    relax,
  ];

  /// The built-in interest with [key], or null.
  static PlaceInterest? fromKey(String key) {
    for (final interest in values) {
      if (interest.key == key) return interest;
    }
    return null;
  }

  /// The interests for [keys], without repeats, in [catalogue] order.
  /// Keys the catalogue does not list are dropped.
  static List<PlaceInterest> fromKeys(
    Iterable<String> keys, {
    List<PlaceInterest> catalogue = values,
  }) {
    final wanted = keys.toSet();
    return [
      for (final interest in catalogue)
        if (wanted.contains(interest.key)) interest,
    ];
  }

  /// [current] plus [pick], without repeats, in display order.
  static List<PlaceInterest> withPick(
    Iterable<PlaceInterest> current,
    PlaceInterest pick,
  ) {
    final byKey = {for (final i in current) i.key: i, pick.key: pick};
    return byKey.values.toList()..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
    });
  }

  /// Stored keys as interests, in the stored order and without repeats.
  /// Keys no interest is known for are kept as [PlaceInterest.unlisted], so
  /// an answer is never trimmed just because the catalogue is not loaded.
  static List<PlaceInterest> fromStoredKeys(Iterable<String> keys) => [
    for (final key in keys.toSet()) fromKey(key) ?? PlaceInterest.unlisted(key),
  ];

  @override
  bool operator ==(Object other) => other is PlaceInterest && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'PlaceInterest($key)';
}

/// What the traveller told us in setup: their picks, and whether the
/// question has been answered (an empty list with [completed] true is a
/// skip).
class InterestsAnswer {
  const InterestsAnswer({required this.interests, required this.completed});

  const InterestsAnswer.unanswered() : interests = const [], completed = false;

  final List<PlaceInterest> interests;
  final bool completed;

  InterestsAnswer copyWith({List<PlaceInterest>? interests, bool? completed}) =>
      InterestsAnswer(
        interests: interests ?? this.interests,
        completed: completed ?? this.completed,
      );
}

/// How the saved interests read in a settings row: "Not set", or the
/// first two names and a count of the rest, e.g. "Waterfalls, coast +1".
String interestsSummary(List<PlaceInterest> interests) {
  if (interests.isEmpty) return 'Not set';
  final names = [for (final i in interests.take(2)) i.shortName];
  names[0] = names[0][0].toUpperCase() + names[0].substring(1);
  final extra = interests.length - names.length;
  return '${names.join(', ')}${extra > 0 ? ' +$extra' : ''}';
}
