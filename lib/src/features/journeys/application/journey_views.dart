import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/journey_route.dart';
import '../domain/journey_summary.dart';
import 'journey_cloud_providers.dart';
import 'journey_providers.dart';
import 'journey_recorder.dart';

part 'journey_views.g.dart';

/// The active Journey's route as it's recorded (empty when none).
@riverpod
Stream<JourneyRoute> activeJourneyRoute(Ref ref) {
  final session = ref.watch(journeyRecorderProvider);
  if (session == null) return Stream.value(JourneyRoute(const []));
  return ref
      .watch(localJourneyRepositoryProvider)
      .watchPoints(session.id)
      .map(JourneyRoute.new);
}

/// One past Journey with its route: from this phone while it waits to
/// upload, else from the cloud.
class JourneyDetail {
  const JourneyDetail({required this.summary, required this.route});

  final JourneySummary summary;
  final JourneyRoute route;
}

class JourneyNotFound implements Exception {
  const JourneyNotFound();
}

@riverpod
Future<JourneyDetail> journeyDetail(Ref ref, String id) async {
  ref.watch(authUserIdProvider);
  final userId = ref.watch(currentUserIdProvider)();
  if (userId == null) throw const JourneyNotFound();

  final queue = ref.watch(journeyUploadQueueProvider);
  final waiting = queue == null
      ? const <JourneySummary>[]
      : await queue.pending(userId);
  for (final summary in waiting) {
    if (summary.id == id) {
      final points = await ref
          .watch(localJourneyRepositoryProvider)
          .points(id, userId);
      return JourneyDetail(summary: summary, route: JourneyRoute(points));
    }
  }

  final cloud = ref.watch(supabaseJourneyRepositoryProvider);
  final summary = await cloud?.journey(id);
  if (cloud == null || summary == null) throw const JourneyNotFound();
  return JourneyDetail(
    summary: summary,
    route: JourneyRoute(await cloud.points(id)),
  );
}
