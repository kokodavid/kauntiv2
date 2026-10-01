import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/app_logger.dart';
import '../../auth/application/auth_providers.dart';
import '../data/local_journey_repository.dart';
import '../domain/journey_destination.dart';
import '../domain/journey_fix.dart';
import '../domain/journey_ids.dart';
import '../domain/pro_status.dart';
import 'journey_cloud_providers.dart';
import 'journey_entitlement.dart';
import 'journey_history.dart';
import 'journey_providers.dart';

part 'journey_recorder.g.dart';

/// The active Journey for the signed-in account: Pro-gated start, pause,
/// resume and finish, and recovery after a restart. Finishing queues upload.
///
/// Bound to one account: when the signed-in account changes, a recording
/// Journey is paused for its owner and let go, so the next account never
/// sees or continues it.
@Riverpod(keepAlive: true)
class JourneyRecorder extends _$JourneyRecorder {
  static const _logger = AppLogger.journeys();

  /// Who [state] belongs to.
  String? _owner;
  Future<void>? _releaseInFlight;

  @override
  LocalJourneySession? build() {
    final capture = ref.read(journeyCaptureProvider);
    capture.onUnexpectedPause = (session) {
      final owner = _owner;
      if (owner != null && _stillOwnedBy(owner) && state?.id == session.id) {
        _set(session, owner);
      }
    };
    ref.onDispose(() => capture.onUnexpectedPause = null);
    ref.listen(authUserIdProvider, (_, next) {
      if (next.isLoading || !next.hasValue) return;
      final owner = _owner;
      if (owner != null && next.value != owner) {
        final release = _releaseForAccountChange();
        _releaseInFlight = release;
        unawaited(
          release
              .then<void>(
                (_) {},
                onError: (Object error, StackTrace stack) {
                  _logger.warning(
                    'Journey location cleanup after account change failed.',
                    error: error,
                    stackTrace: stack,
                  );
                },
              )
              .whenComplete(() {
                if (identical(_releaseInFlight, release)) {
                  _releaseInFlight = null;
                }
              }),
        );
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

  bool _stillOwnedBy(String userId) =>
      ref.read(currentUserIdProvider)() == userId;

  Future<void> _detachPreviousOwner(String userId) async {
    final release = _releaseInFlight;
    if (release != null) await release;
    final capture = ref.read(journeyCaptureProvider);
    if (capture.ownerUserId != null && capture.ownerUserId != userId) {
      await capture.detach();
    }
  }

  /// After launch: a Journey left recording is paused (the gap while the
  /// app was closed isn't recorded) and waits for an explicit Resume.
  Future<void> recover() async {
    if (state != null) return;
    final userId = _userId();
    await _detachPreviousOwner(userId);
    final capture = ref.read(journeyCaptureProvider);
    final session = await capture.recover(userId);
    if (!_stillOwnedBy(userId)) {
      await capture.detach();
      return;
    }
    _set(session, userId);
  }

  /// Starts a Journey. Throws [JourneyTrialExhausted] when neither Pro
  /// nor the free Trip allowance for this month permit it,
  /// [JourneyProCheckUnavailable] when entitlement can't be checked
  /// (offline) and [JourneyLocationException] when the phone can't record.
  Future<void> start({DateTime? now, JourneyDestination? destination}) async {
    if (state != null) throw StateError('A Journey is already in progress.');
    final userId = _userId();
    await _detachPreviousOwner(userId);
    final at = now ?? DateTime.now();
    await ref.read(journeyEntitlementProvider.notifier).canStart(now: at);
    if (!_stillOwnedBy(userId)) {
      throw StateError('Account changed while starting a Journey.');
    }
    final session = await ref
        .read(localJourneyRepositoryProvider)
        .start(
          id: JourneyIds.newId(),
          userId: userId,
          at: at.toUtc(),
          destination: destination,
        );
    if (!_stillOwnedBy(userId)) {
      await ref
          .read(localJourneyRepositoryProvider)
          .discard(session.id, userId);
      throw StateError('Account changed while starting a Journey.');
    }
    final capture = ref.read(journeyCaptureProvider);
    try {
      await capture.attachStarted(session: session, userId: userId);
      if (!_stillOwnedBy(userId)) {
        throw StateError('Account changed while starting a Journey.');
      }
      _set(capture.session, userId);
    } on JourneyLocationException {
      // The phone can't record (location off, no "Always" permission,
      // background mode refused): nothing was recorded, so the Journey is
      // dropped rather than left paused.
      await capture.detach();
      await ref
          .read(localJourneyRepositoryProvider)
          .discard(session.id, userId);
      _set(null, null);
      rethrow;
    } catch (_) {
      if (_stillOwnedBy(userId)) {
        // Capture keeps the Journey, paused; show that.
        _set(capture.session, userId);
      } else {
        await capture.detach();
        _set(null, null);
      }
      rethrow;
    }
  }

  Future<void> pause() async {
    _requireOwner();
    final userId = _owner!;
    final capture = ref.read(journeyCaptureProvider);
    try {
      final session = await capture.pause();
      _set(_stillOwnedBy(userId) ? session : null, userId);
    } on JourneyTeardownException {
      _set(_stillOwnedBy(userId) ? capture.session : null, userId);
      rethrow;
    }
  }

  Future<void> resume() async {
    _requireOwner();
    final userId = _owner!;
    final capture = ref.read(journeyCaptureProvider);
    try {
      final session = await capture.resume();
      _set(_stillOwnedBy(userId) ? session : null, userId);
    } on JourneyTeardownException {
      _set(_stillOwnedBy(userId) ? capture.session : null, userId);
      rethrow;
    }
  }

  /// Ends the Journey and uploads it (now, or later if offline).
  Future<void> finish() async {
    _requireOwner();
    final userId = _owner!;
    final capture = ref.read(journeyCaptureProvider);
    try {
      await capture.finish();
    } on JourneyTeardownException {
      _set(_stillOwnedBy(userId) ? capture.session : null, userId);
      rethrow;
    }
    if (!ref.mounted) return;
    _set(null, null);
    if (!_stillOwnedBy(userId)) return;
    ref.invalidate(journeyHistoryListProvider);
    // Refreshed only after the drain finishes, so a just-recorded Trip's
    // own upload has already had a chance to move the count before the
    // Start card's usage pill re-reads it.
    unawaited(
      ref
          .read(journeySyncProvider.notifier)
          .drain()
          .then(
            (_) =>
                ref.read(journeyEntitlementProvider.notifier).refreshAccess(),
          ),
    );
  }

  /// Ends the Journey without saving it: the route is deleted from this
  /// phone and nothing is uploaded.
  Future<void> discard() async {
    _requireOwner();
    final session = state;
    final userId = _owner;
    if (session == null || userId == null) return;
    final capture = ref.read(journeyCaptureProvider);
    try {
      // Do not erase the route until native background capture has stopped.
      await capture.detach();
    } on JourneyTeardownException {
      _set(_stillOwnedBy(userId) ? capture.session : null, userId);
      rethrow;
    }
    await ref.read(localJourneyRepositoryProvider).discard(session.id, userId);
    _set(null, null);
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
