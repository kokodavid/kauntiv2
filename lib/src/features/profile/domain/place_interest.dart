/// The kinds of places a traveller can say they like (setup step 2 and
/// Settings > Interests). [key] is what is stored on
/// `profiles.interests`; keep the list in step with the check constraint
/// in `20261012100000_add_profile_interests.sql`.
enum PlaceInterest {
  nature('nature', 'Nature and parks', 'parks'),
  water('water', 'Waterfalls and hikes', 'waterfalls'),
  coast('coast', 'Beaches and coast', 'coast'),
  culture('culture', 'Culture and history', 'heritage sites'),
  wild('wild', 'Wildlife', 'wildlife'),
  food('food', 'Food and markets', 'markets'),
  views('views', 'Views and viewpoints', 'viewpoints'),
  relax('relax', 'Relaxing spots', 'quiet spots');

  const PlaceInterest(this.key, this.label, this.shortName);

  final String key;
  final String label;

  /// Lower-case noun used in a sentence ("find waterfalls near you").
  final String shortName;

  static PlaceInterest? fromKey(String key) {
    for (final interest in values) {
      if (interest.key == key) return interest;
    }
    return null;
  }

  /// Keys that are known interests, in canonical order, without repeats.
  static List<PlaceInterest> fromKeys(Iterable<String> keys) {
    final wanted = keys.toSet();
    return [
      for (final interest in values)
        if (wanted.contains(interest.key)) interest,
    ];
  }
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
