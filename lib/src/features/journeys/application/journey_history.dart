import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/journey_summary.dart';
import 'journey_cloud_providers.dart';

part 'journey_history.g.dart';

/// Past Journeys: the ones still waiting on this phone first, then the
/// private cloud history. Readable with or without Pro.
class JourneyHistory {
  const JourneyHistory({required this.journeys, this.cloudUnavailable = false});

  final List<JourneySummary> journeys;

  /// The cloud list couldn't load (offline); only local ones are shown.
  final bool cloudUnavailable;
}

@riverpod
class JourneyHistoryList extends _$JourneyHistoryList {
  @override
  Future<JourneyHistory> build() async {
    final userId = ref.watch(currentUserIdProvider)();
    if (userId == null) return const JourneyHistory(journeys: []);
    final queue = ref.watch(journeyUploadQueueProvider);
    final cloud = ref.watch(supabaseJourneyRepositoryProvider);
    final pending = queue == null
        ? const <JourneySummary>[]
        : await queue.pending(userId);
    if (cloud == null) return JourneyHistory(journeys: pending);
    try {
      final uploaded = await cloud.history();
      final pendingIds = {for (final j in pending) j.id};
      return JourneyHistory(
        journeys: [
          ...pending,
          for (final j in uploaded)
            if (!pendingIds.contains(j.id)) j,
        ],
      );
    } on Object {
      return JourneyHistory(journeys: pending, cloudUnavailable: true);
    }
  }

  /// Deletes a Journey: from the cloud once uploaded, else from this phone.
  Future<void> delete(JourneySummary journey) async {
    if (journey.isUploaded) {
      await ref.read(supabaseJourneyRepositoryProvider)?.delete(journey.id);
    } else {
      final userId = ref.read(currentUserIdProvider)();
      if (userId != null) {
        await ref.read(journeyUploadQueueProvider)?.deleteLocal(
          journey.id,
          userId,
        );
      }
    }
    ref.invalidateSelf();
  }
}
