import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../../discover/application/explore_providers.dart';
import '../data/visit_sync_queue.dart';
import 'detection_providers.dart';

part 'visit_sync.g.dart';

/// The upload queue for the signed-in user, or null when Supabase isn't
/// configured for this build.
@Riverpod(keepAlive: true)
VisitSyncQueue? visitSyncQueue(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return VisitSyncQueue.supabase(ref.watch(detectionDatabaseProvider), client);
}

/// Drains queued visits and keeps the rest of the app in step. The state
/// counts visits synced this session, so screens that show visit state
/// can watch it and reload when it changes.
@Riverpod(keepAlive: true)
class VisitSync extends _$VisitSync {
  @override
  int build() => 0;

  /// Uploads what's due. When anything synced, Explore's board reloads so
  /// a new badge shows without a restart.
  Future<int> drain() async {
    final queue = ref.read(visitSyncQueueProvider);
    if (queue == null) return 0;
    final synced = await queue.drain();
    if (synced > 0) {
      state = state + synced;
      ref.invalidate(exploreBoardProvider);
    }
    return synced;
  }
}
