import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/pro_status.dart';
import 'journey_cloud_providers.dart';

part 'journey_entitlement.g.dart';

/// Pro for starting a Journey. The server is asked first; its answer is
/// cached so a start also works offline for up to
/// [ProStatus.maxCacheAge]. This only gates the Start button: the upload
/// re-checks Pro on the server, so a stale cache can't earn a cloud write.
@Riverpod(keepAlive: true)
class JourneyEntitlement extends _$JourneyEntitlement {
  @override
  ProStatus? build() {
    // A new account starts with no status until it's checked.
    ref.watch(authUserIdProvider);
    return null;
  }

  Future<bool> canStart({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final userId = ref.read(currentUserIdProvider)();
    if (userId == null) return false;
    final cache = ref.read(proStatusCacheProvider);
    final cloud = ref.read(supabaseJourneyRepositoryProvider);
    if (cloud != null) {
      try {
        final fresh = await cloud.proStatus();
        await cache.write(userId, fresh);
        if (ref.mounted) state = fresh;
        return fresh.allowsStartAt(at);
      } on Object {
        // Offline or unreachable: fall back to the last confirmed status.
      }
    }
    final cached = await cache.read(userId);
    if (ref.mounted) state = cached;
    return cached?.allowsStartAt(at, fromCache: true) ?? false;
  }
}
