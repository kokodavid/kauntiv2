import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_config_provider.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../core/services/fail_fast.dart';
import '../../../core/services/last_screen.dart';
import '../../auth/application/auth_providers.dart';
import '../data/feedback_outbox_store.dart';
import '../data/feedback_repository.dart';
import '../domain/feedback_models.dart';
import 'feedback_providers.dart';

part 'feedback_submit_providers.g.dart';

/// Reports written without a connection, waiting to be sent. The state is
/// how many are waiting; [flush] sends them when there is signal.
@riverpod
class FeedbackOutboxSync extends _$FeedbackOutboxSync {
  @override
  Future<int> build() async {
    final owner = ref.watch(authUserIdProvider).value;
    if (owner == null) return 0;
    return (await ref.read(feedbackOutboxStoreProvider).all(owner)).length;
  }

  /// Send what is waiting. Quiet when offline or when nothing is waiting;
  /// stops at the first report that cannot reach the server.
  Future<void> flush() async {
    // Let the first count finish so it cannot overwrite the result below.
    try {
      await future;
    } on Object {
      // An unreadable outbox just reads as empty.
    }
    final owner = ref.read(currentUserIdProvider)();
    final repository = ref.read(feedbackRepositoryProvider);
    if (owner == null || repository == null) return;
    if (ref.read(connectivityProvider).isOffline) return;
    final store = ref.read(feedbackOutboxStoreProvider);
    for (final item in await store.all(owner)) {
      try {
        await repository.submit(item.draft, item.context);
        await store.remove(owner, item.draft.clientId);
      } on Object catch (error) {
        if (feedbackIsUnreachable(error)) break;
        // Refused for good (seat revoked, text rejected): drop it so it
        // cannot hold up the rest.
        if (feedbackIsRefused(error)) {
          await store.remove(owner, item.draft.clientId);
        }
      }
    }
    final left = (await store.all(owner)).length;
    if (ref.mounted) state = AsyncData(left);
  }
}

/// Files one report. The state is null until a report is sent, then the
/// outcome: filed (with its reference) or saved for when there is signal.
@riverpod
class FeedbackSubmitter extends _$FeedbackSubmitter {
  @override
  FutureOr<FeedbackSubmission?> build() => null;

  static const _patience = Duration(seconds: 90);

  Future<void> submit(FeedbackDraft draft) async {
    final repository = ref.read(feedbackRepositoryProvider);
    final owner = ref.read(currentUserIdProvider)();
    if (repository == null || owner == null) {
      state = AsyncError(
        const FeedbackFailure('Sign in to send feedback.'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading();
    final context = await ref
        .read(feedbackContextSourceProvider)
        .capture(
          screen: ref.read(lastScreenProvider),
          flavor: ref.read(appConfigProvider).environment.name,
        );
    try {
      final result = await failFast(
        ref,
        () => repository.submit(draft, context),
        patience: _patience,
      );
      ref.invalidate(myFeedbackProvider);
      if (ref.mounted) state = AsyncData(result);
    } on Object catch (error, stack) {
      if (feedbackIsUnreachable(error)) {
        await ref
            .read(feedbackOutboxStoreProvider)
            .add(owner, PendingFeedback(draft: draft, context: context));
        ref.invalidate(feedbackOutboxSyncProvider);
        if (ref.mounted) state = const AsyncData(FeedbackSubmission.queued());
      } else if (ref.mounted) {
        state = AsyncError(FeedbackFailure(feedbackFailureMessage(error)), stack);
      }
    }
  }

  /// Back to a blank form.
  void reset() => state = const AsyncData(null);
}
