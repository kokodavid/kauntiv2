import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/config/app_config.dart';
import 'package:kaunti47_v2/src/core/domain/connectivity_state.dart';
import 'package:kaunti47_v2/src/core/services/app_config_provider.dart';
import 'package:kaunti47_v2/src/core/services/connectivity_provider.dart';
import 'package:kaunti47_v2/src/features/auth/application/auth_providers.dart';
import 'package:kaunti47_v2/src/features/feedback/application/feedback_providers.dart';
import 'package:kaunti47_v2/src/features/feedback/application/feedback_submit_providers.dart';
import 'package:kaunti47_v2/src/features/feedback/data/feedback_context_source.dart';
import 'package:kaunti47_v2/src/features/feedback/data/feedback_outbox_store.dart';
import 'package:kaunti47_v2/src/features/feedback/data/feedback_repository.dart';
import 'package:kaunti47_v2/src/features/feedback/domain/feedback_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Online extends Connectivity {
  @override
  ConnectivityState build() =>
      const ConnectivityState(status: ConnectivityStatus.online);
}

class _Context extends FeedbackContextSource {
  const _Context();

  @override
  Future<FeedbackContext> capture({String? screen, String? flavor}) async =>
      FeedbackContext(screen: screen, flavor: flavor, capturedAt: DateTime(2026));
}

class _MemoryOutbox extends FeedbackOutboxStore {
  final items = <PendingFeedback>[];

  @override
  Future<List<PendingFeedback>> all(String owner) async => [...items];

  @override
  Future<void> add(String owner, PendingFeedback pending) async =>
      items.add(pending);

  @override
  Future<void> remove(String owner, String clientId) async =>
      items.removeWhere((p) => p.draft.clientId == clientId);
}

class _Repository implements FeedbackRepository {
  _Repository(this.onSubmit);

  final Future<FeedbackSubmission> Function() onSubmit;
  int submitted = 0;

  @override
  Future<bool?> cachedHasTesterSeat() async => true;

  @override
  Future<bool> hasTesterSeat() async => true;

  @override
  Future<List<FeedbackReport>> mine() async => const [];

  @override
  Future<FeedbackSubmission> submit(
    FeedbackDraft draft,
    FeedbackContext context,
  ) {
    submitted++;
    return onSubmit();
  }
}

FeedbackDraft _draft() => FeedbackDraft(
  clientId: FeedbackDraft.newClientId(),
  category: FeedbackCategory.bug,
  severity: FeedbackSeverity.major,
  title: 'Map flickers',
  description: 'The map flickers when I open Home.',
);

void main() {
  late _MemoryOutbox outbox;

  ProviderContainer containerFor(_Repository repository) {
    outbox = _MemoryOutbox();
    final container = ProviderContainer(
      overrides: [
        connectivityProvider.overrideWith(_Online.new),
        appConfigProvider.overrideWithValue(const AppConfig.dev()),
        currentUserIdProvider.overrideWithValue(() => 'user-1'),
        authUserIdProvider.overrideWith((ref) => Stream.value('user-1')),
        feedbackRepositoryProvider.overrideWithValue(repository),
        feedbackContextSourceProvider.overrideWithValue(const _Context()),
        feedbackOutboxStoreProvider.overrideWithValue(outbox),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a filed report returns its reference', () async {
    final container = containerFor(
      _Repository(
        () async => const FeedbackSubmission.sent(
          FeedbackReceipt(id: 'r1', reference: 'FB-0007'),
        ),
      ),
    );
    container.listen(feedbackSubmitterProvider, (_, _) {});
    await container.read(feedbackSubmitterProvider.notifier).submit(_draft());
    final result = container.read(feedbackSubmitterProvider).value;
    expect(result?.receipt?.reference, 'FB-0007');
    expect(outbox.items, isEmpty);
  });

  test('no connection saves the report to send later', () async {
    final container = containerFor(
      _Repository(() async => throw const SocketException('no route')),
    );
    container.listen(feedbackSubmitterProvider, (_, _) {});
    await container.read(feedbackSubmitterProvider.notifier).submit(_draft());
    final result = container.read(feedbackSubmitterProvider).value;
    expect(result?.queued, isTrue);
    expect(outbox.items, hasLength(1));
  });

  test('a refused report is shown to the tester and not saved', () async {
    final container = containerFor(
      _Repository(
        () async => throw const PostgrestException(
          message: 'Feedback is open to beta testers only',
          code: '42501',
        ),
      ),
    );
    container.listen(feedbackSubmitterProvider, (_, _) {});
    await container.read(feedbackSubmitterProvider.notifier).submit(_draft());
    final state = container.read(feedbackSubmitterProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<FeedbackFailure>());
    expect(outbox.items, isEmpty);
  });

  test('flush sends saved reports and keeps the ones that cannot go', () async {
    var reachable = false;
    final repository = _Repository(() async {
      if (!reachable) throw const SocketException('no route');
      return const FeedbackSubmission.sent(
        FeedbackReceipt(id: 'r', reference: 'FB-0001'),
      );
    });
    final container = containerFor(repository);
    container.listen(feedbackSubmitterProvider, (_, _) {});
    container.listen(feedbackOutboxSyncProvider, (_, _) {});
    await container.read(feedbackSubmitterProvider.notifier).submit(_draft());
    expect(outbox.items, hasLength(1));

    await container.read(feedbackOutboxSyncProvider.notifier).flush();
    expect(outbox.items, hasLength(1), reason: 'still unreachable');

    reachable = true;
    await container.read(feedbackOutboxSyncProvider.notifier).flush();
    expect(outbox.items, isEmpty);
    expect(container.read(feedbackOutboxSyncProvider).value, 0);
  });
}
