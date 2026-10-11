/// Where the phone's connection stands, as the offline widgets show it.
enum ConnectivityStatus {
  /// Reachable (or not yet known to be otherwise): nothing is shown.
  online,

  /// Confirmed unreachable for a moment: the banner shows.
  offline,

  /// A Retry is being checked (shown for at least a beat).
  checking,

  /// The connection just came back and the app is catching up.
  reconnecting,

  /// Caught up; shown briefly before the banner leaves.
  upToDate,
}

class ConnectivityState {
  const ConnectivityState({
    this.status = ConnectivityStatus.online,
    this.lastSyncedAt,
  });

  final ConnectivityStatus status;

  /// When the app last finished catching up after a reconnect.
  final DateTime? lastSyncedAt;

  /// Cut off from the server: notices stand in for sections that need it.
  bool get isOffline =>
      status == ConnectivityStatus.offline ||
      status == ConnectivityStatus.checking;

  /// The banner is visible in every state but plain online.
  bool get showsBanner => status != ConnectivityStatus.online;

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    DateTime? lastSyncedAt,
  }) => ConnectivityState(
    status: status ?? this.status,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
}
