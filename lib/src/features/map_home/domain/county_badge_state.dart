enum CountyBadgeState { earned, locked, passedThrough, pending, justUnlocked }

extension CountyBadgeStateLabel on CountyBadgeState {
  /// The traveller's standing in a county, as the map's county label and
  /// the county preview show it.
  String get statusLabel => switch (this) {
    CountyBadgeState.earned => 'EARNED',
    CountyBadgeState.locked => 'UNCLAIMED',
    CountyBadgeState.passedThrough => 'PASSED THROUGH',
    CountyBadgeState.pending => 'PENDING',
    CountyBadgeState.justUnlocked => 'JUST UNLOCKED',
  };
}
