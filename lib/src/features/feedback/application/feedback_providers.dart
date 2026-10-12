import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/fail_fast.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/feedback_context_source.dart';
import '../data/feedback_outbox_store.dart';
import '../data/feedback_repository.dart';
import '../domain/feedback_models.dart';
import 'feedback_submit_providers.dart';

part 'feedback_providers.g.dart';

/// Null when the build has no Supabase. Tests override it.
@riverpod
FeedbackRepository? feedbackRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseFeedbackRepository(client);
}

@riverpod
FeedbackOutboxStore feedbackOutboxStore(Ref ref) => const FeedbackOutboxStore();

@riverpod
FeedbackContextSource feedbackContextSource(Ref ref) =>
    const FeedbackContextSource();

/// Whether the signed-in account holds an active tester seat. Answers from
/// the copy remembered on this phone first so the Profile entry does not
/// pop in late, then confirms with the server. A failed check keeps the
/// remembered answer; with none, the answer is no.
@riverpod
Stream<bool> hasTesterSeat(Ref ref) async* {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(feedbackRepositoryProvider);
  if (repository == null) {
    yield false;
    return;
  }
  final cached = await repository.cachedHasTesterSeat();
  if (cached != null) yield cached;
  try {
    yield await failFast(ref, repository.hasTesterSeat);
  } on Object {
    if (cached == null) yield false;
  }
}

/// The signed-in tester's own reports, newest first. Sends anything saved
/// while offline before reading, so a report written on the road shows up
/// as soon as there is signal.
@riverpod
Future<List<FeedbackReport>> myFeedback(Ref ref) async {
  ref.watch(authUserIdProvider);
  final repository = ref.watch(feedbackRepositoryProvider);
  if (repository == null) return const [];
  await ref.read(feedbackOutboxSyncProvider.notifier).flush();
  return failFast(ref, repository.mine);
}
