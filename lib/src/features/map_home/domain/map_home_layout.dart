/// Which order Home's bottom sheet uses. The sections are always the same;
/// only their order and prominence change. See the Home sheet redesign.
enum MapHomeLayout {
  /// A county was claimed a moment ago: celebrate, then the next goal.
  claim,

  /// A Trip is recording: one compact card for the nearest unclaimed county.
  recording,

  /// Nothing claimed yet: start with the home county.
  newUser,

  /// Every county claimed: celebrate, then go deeper inside them.
  complete,

  /// Everything else.
  standard,
}

/// The sections the sheet is made of. A layout is a list of these; a new
/// section registers an id here and a card type in the presentation layer.
enum MapHomeSection {
  /// "Nakuru is yours": the win, with the 47-segment bar.
  celebration,

  /// Collapsed-only card: the nearest unclaimed county and one button.
  compactTarget,

  /// The home county as the first target (new users).
  homeCountyTarget,

  /// "Your next best move" (promotion, saved place, depth rank, or the
  /// nearest unclaimed county).
  primaryTarget,

  /// The nearest unclaimed county as the next goal (after a claim).
  nextGoal,

  /// "Nearby and unclaimed" row.
  nearbyUnclaimed,

  /// Depth-rank place suggestions once there is nothing left to claim.
  goDeeper,

  /// The user's saved plans, supplied by another feature. Hides when empty.
  savedPlans,

  /// Public trips row, supplied by another feature. Hides when empty.
  tripsNear,
}

/// Picks the layout and its sections from signals the app already has.
/// Pure: the caller reads the signals once when Home opens and again only
/// when a county is claimed or a Trip starts or stops.
abstract final class MapHomeLayoutRules {
  /// How long after claiming a county the celebration can show.
  static const claimWindow = Duration(minutes: 30);

  /// Whether a claim at [claimedAt] should be celebrated now: it is inside
  /// [claimWindow] and has not been celebrated already (one open only).
  static bool isFreshClaim({
    required DateTime? claimedAt,
    required DateTime now,
    DateTime? celebratedAt,
  }) {
    if (claimedAt == null) return false;
    final age = now.difference(claimedAt);
    if (age.isNegative || age > claimWindow) return false;
    return celebratedAt == null || celebratedAt.isBefore(claimedAt);
  }

  /// Precedence: a fresh claim, then a recording Trip, then a finished
  /// map, then a user with nothing claimed, then the standard order.
  static MapHomeLayout pick({
    required int claimedCount,
    required int totalCounties,
    required bool isTripRecording,
    required bool hasFreshClaim,
  }) {
    if (hasFreshClaim) return MapHomeLayout.claim;
    if (isTripRecording) return MapHomeLayout.recording;
    if (totalCounties > 0 && claimedCount >= totalCounties) {
      return MapHomeLayout.complete;
    }
    if (claimedCount == 0) return MapHomeLayout.newUser;
    return MapHomeLayout.standard;
  }

  static List<MapHomeSection> sections(MapHomeLayout layout) =>
      switch (layout) {
        MapHomeLayout.claim => const [
          MapHomeSection.celebration,
          MapHomeSection.nextGoal,
          MapHomeSection.nearbyUnclaimed,
        ],
        MapHomeLayout.recording => const [
          MapHomeSection.compactTarget,
          MapHomeSection.nearbyUnclaimed,
        ],
        MapHomeLayout.complete => const [
          MapHomeSection.celebration,
          MapHomeSection.goDeeper,
        ],
        MapHomeLayout.newUser => const [
          MapHomeSection.homeCountyTarget,
          MapHomeSection.nearbyUnclaimed,
          MapHomeSection.tripsNear,
        ],
        MapHomeLayout.standard => const [
          MapHomeSection.primaryTarget,
          MapHomeSection.savedPlans,
          MapHomeSection.nearbyUnclaimed,
          MapHomeSection.tripsNear,
        ],
      };

  /// The sheet opens expanded to show the win; every other layout opens
  /// collapsed to its compact card. A sheet the user has opened is never
  /// collapsed for them.
  static bool startsExpanded(MapHomeLayout layout) =>
      layout == MapHomeLayout.claim || layout == MapHomeLayout.complete;
}
