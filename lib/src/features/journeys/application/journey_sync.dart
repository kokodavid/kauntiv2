import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'journey_cloud_providers.dart';
import 'journey_history.dart';

part 'journey_sync.g.dart';

/// Drains the Journey upload queue; the state counts uploads this session.
@Riverpod(keepAlive: true)
class JourneySync extends _$JourneySync {
  @override
  int build() => 0;

  Future<int> drain() async {
    final queue = ref.read(journeyUploadQueueProvider);
    final uploaded = queue == null ? 0 : await queue.drain();
    if (uploaded > 0 && ref.mounted) {
      state = state + uploaded;
      ref.invalidate(journeyHistoryListProvider);
    }
    final mediaQueue = ref.read(journeyMediaUploadQueueProvider);
    if (mediaQueue != null) await mediaQueue.drain();
    return uploaded;
  }
}
