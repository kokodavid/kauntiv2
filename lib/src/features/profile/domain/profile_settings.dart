/// Who can see this account's claimed-county map (Settings > Privacy).
enum MapVisibility {
  private,
  friends,
  public;

  static MapVisibility fromColumn(String value) => switch (value) {
    'private' => private,
    'public' => public,
    _ => friends,
  };

  String get column => switch (this) {
    private => 'private',
    friends => 'friends',
    public => 'public',
  };

  String get label => switch (this) {
    private => 'Private',
    friends => 'Friends',
    public => 'Public',
  };
}

/// How counties are claimed (Settings > Location > "County detection").
/// Stored on `profiles.location_mode`; today this is a saved preference
/// only -- [DetectionController] always runs the automatic background
/// cycle regardless of this value. Making "Manual" actually suspend
/// background detection is a separate, deeper change to the detection
/// feature and isn't wired by this settings screen.
enum LocationMode {
  automatic,
  manual;

  static LocationMode fromColumn(String value) =>
      value == 'manual' ? manual : automatic;

  String get column => switch (this) {
    automatic => 'automatic',
    manual => 'manual',
  };
}

/// The five preference columns Settings actually surfaces, plus
/// `locationMode`, read together from one row of `profiles`.
class ProfileSettings {
  const ProfileSettings({
    required this.mapVisibility,
    required this.showOnLeaderboards,
    required this.notifyBadgeUnlocks,
    required this.notifyCountyNudges,
    required this.sideQuestRadiusKm,
    required this.locationMode,
  });

  final MapVisibility mapVisibility;
  final bool showOnLeaderboards;
  final bool notifyBadgeUnlocks;
  final bool notifyCountyNudges;
  final int sideQuestRadiusKm;
  final LocationMode locationMode;

  /// The radii the radius chooser offers (`side_quest_radius_km`'s check
  /// constraint: `in (25, 50, 100, 250, 500)`).
  static const radiusChoicesKm = [25, 50, 100, 250, 500];

  ProfileSettings copyWith({
    MapVisibility? mapVisibility,
    bool? showOnLeaderboards,
    bool? notifyBadgeUnlocks,
    bool? notifyCountyNudges,
    int? sideQuestRadiusKm,
    LocationMode? locationMode,
  }) => ProfileSettings(
    mapVisibility: mapVisibility ?? this.mapVisibility,
    showOnLeaderboards: showOnLeaderboards ?? this.showOnLeaderboards,
    notifyBadgeUnlocks: notifyBadgeUnlocks ?? this.notifyBadgeUnlocks,
    notifyCountyNudges: notifyCountyNudges ?? this.notifyCountyNudges,
    sideQuestRadiusKm: sideQuestRadiusKm ?? this.sideQuestRadiusKm,
    locationMode: locationMode ?? this.locationMode,
  );
}
