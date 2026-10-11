import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'connectivity_provider.dart';

part 'offline_screen_presence.g.dart';

/// How many full-screen "You're offline" states are showing right now. The
/// banner steps aside while one is, so the message isn't said twice.
@Riverpod(keepAlive: true)
class OfflineScreenPresence extends _$OfflineScreenPresence {
  @override
  int build() => 0;

  void enter() => state = state + 1;

  void leave() => state = state > 0 ? state - 1 : 0;
}

/// Whether the offline banner should stay hidden: a full-screen offline
/// state is up and the phone is still cut off. Once the connection returns
/// the banner is free to show "Back online".
@riverpod
bool offlineBannerSuppressed(Ref ref) {
  final screens = ref.watch(offlineScreenPresenceProvider);
  final offline = ref.watch(connectivityProvider.select((s) => s.isOffline));
  return screens > 0 && offline;
}
