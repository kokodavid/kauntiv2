import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/local_journey_repository.dart';
import '../domain/journey_ids.dart';
import '../domain/pro_status.dart';
import 'journey_cloud_providers.dart';
import 'journey_entitlement.dart';
import 'journey_history.dart';
import 'journey_providers.dart';

part 'journey_recorder.g.dart';

/// The active Journey for the signed-in account: Pro-gated start, pause,
/// resume and finish, and recovery after a restart. Finishing queues the
/// upload. No UI calls this yet (Journeys step 4).
///
/// Bound to one account: when the signed-in account changes, a recording
/// Journey is paused for its owner and let go, so the next account never
/// sees or continues it.
@Riverpod(keepAlive: true)
class JourneyRecorder extends _$JourneyRecorder {
  /// Who [state] belongs to.
  String? _owner;

  @override
  LocalJourneySession? build() {
    ref.listen(authUserIdProvider, (_, next) {
      final owner = _owner;
      if (owner != null && next.value != owner) {
        unawaited(_releaseForAccountChange());
      }
    });
    return null;
  }

  void _set(LocalJourneySession? session, String? owner) {
    if (!ref.mounted) return;
    _owner = session == null ? null : owner;
    state = session;
  }

  Future<void> _releaseForAccountChange() async {
    _set(null, null);
    await ref.read(journeyCaptureProvider).detach();
  }

  /// Throws unless the attached Journey still belongs to the signed-in
  /// account.
  void _requireOwner() {
    if (_owner != ref.read(currentUserIdProvider)()) {
      throw StateError('This Journey belongs to another account.');
    }
  }

  String _userId() {
    final userId = ref.read(currentUserIdProvider)();
    if (userId == null) throw StateError('Sign in to record a Journey.');
    return userId;
  }

  /// After launch: a Journey left recording is paused (the gap while the
  /// app was closed isn't recorded) and waits for an explicit Resume.
  Future<void> recover() async {
    if (state != null) return;
    final userId = _userId();
    final session = await ref.read(journeyCaptureProvider).recover(userId);
    _set(session, userId);
  }

  /// Starts a Journey. Throws [JourneyStartDenied] without Pro and
  /// [JourneyProCheckUnavailable] when Pro can't be checked (offline).
  Future<void> start({DateTime? now}) async {
    if (state != null) throw StateError('A Journey is already in progress.');
    final userId = _userId();
    final at = now ?? DateTime.now();
    if (!await ref
        .read(journeyEntitlementProvider.notifier)
        .canStart(now: at)) {
      throw const JourneyStartDenied();
    }
    final session = await ref
        .read(localJourneyRepositoryProvider)
        .start(id: JourneyIds.newId(), userId: userId, at: at.toUtc());
    final capture = ref.read(journeyCaptureProvider);
    try {
      await capture.attachStarted(session: session, userId: userId);
    } finally {
      // On failure capture pauses the session; show that state.
      _set(capture.session, userId);
    }
  }

  Future<void> pause() async {
    _requireOwner();
    final session = await ref.read(journeyCaptureProvider).pause();
    _set(session, _owner);
  }

  Future<void> resume() async {
    _requireOwner();
    final session = await ref.read(journeyCaptureProvider).resume();
    _set(session, _owner);
  }

  /// Ends the Journey and uploads it (now, or later if offline).
  Future<void> finish() async {
    _requireOwner();
    await ref.read(journeyCaptureProvider).finish();
    if (!ref.mounted) return;
    _set(null, null);
    ref.invalidate(journeyHistoryListProvider);
    unawaited(ref.read(journeySyncProvider.notifier).drain());
  }
}

/// Drains the Journey upload queue; the state counts uploads this session.
@Riverpod(keepAlive: true)
class JourneySync extends _$JourneySync {
  @override
  int build() => 0;

  Future<int> drain() async {
    final queue = ref.read(journeyUploadQueueProvider);
    if (queue == null) return 0;
    final uploaded = await queue.drain();
    if (uploaded > 0 && ref.mounted) {
      state = state + uploaded;
      ref.invalidate(journeyHistoryListProvider);
    }
    return uploaded;
  }
}
