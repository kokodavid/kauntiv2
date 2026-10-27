/// The five permanent stamps of a county page, lowest first, plus "none".
/// A county never goes back down a level.
enum PassportLevel {
  none,
  passedThrough,
  explored,
  bronze,
  silver,
  gold;

  String get label => switch (this) {
    none => 'Not started',
    passedThrough => 'Passed Through',
    explored => 'Explored',
    bronze => 'Bronze',
    silver => 'Silver',
    gold => 'Gold',
  };

  /// The corner tag on a metal level's cell; null for the others.
  String? get mark => switch (this) {
    bronze => 'B',
    silver => 'S',
    gold => 'G',
    _ => null,
  };

  bool get isMetal => mark != null;

  /// The stamp after this one; null at Gold.
  PassportLevel? get next => switch (this) {
    none => passedThrough,
    passedThrough => explored,
    explored => bronze,
    bronze => silver,
    silver => gold,
    gold => null,
  };

  /// This level is reached or passed once the county is at [other] or above.
  bool isReachedAt(PassportLevel other) => index <= other.index;

  /// The five stamps on a county page, in order.
  static const stamps = [passedThrough, explored, bronze, silver, gold];
}
