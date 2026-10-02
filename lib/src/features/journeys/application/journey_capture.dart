import 'dart:async';

import '../../../services/app_logger.dart';
import '../data/local_journey_repository.dart';
import '../domain/journey_fix.dart';
import '../domain/journey_recording.dart';

/// Drives a server-authorized local session and its location stream.
class JourneyCapture {
  JourneyCapture({
    required LocalJourneyRepository repository,
    required JourneyLocationSource locationSource,
    DateTime Function()? clock,
    this.teardownTimeout = const Duration(seconds: 4),
    this.firstFixTimeout = const Duration(seconds: 20),
  }) : _repository = repository,
       _locationSource = locationSource,
       _clock = clock ?? DateTime.now;

  /// How long each teardown step may take before Stop / Pause carry on
  /// without it. A native call that never returns must not leave the
  /// Journey stuck recording.
  final Duration teardownTimeout;

  /// How long [attachStarted] waits for an actual GPS fix before giving
  /// up. Permission/service checks alone aren't enough - a Simulator or a
  /// phone with a poor signal can pass those and then never deliver a fix,
  /// which is what left Recording running at 0m with no route (see
  /// `JourneyLocationFailure.noFixReceived`).
  final Duration firstFixTimeout;

  final LocalJourneyRepository _repository;
  final JourneyLocationSource _locationSource;
  final DateTime Function() _clock;
  static const _logger = AppLogger.journeys();
  static const missingFixGap = Duration(minutes: 2);

  LocalJourneySession? _session;
  String? _userId;
  StreamSubscription<JourneyFix>? _subscription;
  Completer<void>? _firstFix;
  Future<void>? _canceling;
  Future<void> _writes = Future.value();
  DateTime? _lastRecordedAt;
  bool _closing = false;
  bool _teardownPending = false;
  Object? lastError;
  void Function(LocalJourneySession)? onUnexpectedPause;

  LocalJourneySession? get session => _session;
  String? get ownerUserId => _userId;

  /// A process restart cannot recover locations missed while Dart was dead.
  /// Pause the saved session, so the next Resume begins a new route segment.
  Future<LocalJourneySession?> recover(String userId) async {
    if (_session != null) throw StateError('Capture is already attached.');
    final saved = await _repository.activeSession(userId);
    if (saved == null) return null;
    _userId = userId;
    if (saved.recording.phase == JourneyRecordingPhase.recording) {
      final lastPoint = await _repository.lastPointAt(saved.id, userId);
      final lastChange = saved.recording.lastChangedAt!;
      final stoppedAt = lastPoint != null && lastPoint.isAfter(lastChange)
          ? lastPoint
          : lastChange;
      _session = await _repository.pause(
        id: saved.id,
        userId: userId,
        at: stoppedAt,
      );
    } else {
      _session = saved;
    }
    return _session;
  }

  /// Called immediately after an entitlement-checked caller creates the
  /// local session. No UI invokes this until that caller exists.
  Future<void> attachStarted({
    required LocalJourneySession session,
    required String userId,
  }) async {
    if (_session != null ||
        session.recording.phase != JourneyRecordingPhase.recording) {
      throw StateError('Capture cannot attach this session.');
    }
    _userId = userId;
    _session = session;
    try {
      await _startStream();
      final firstFix = _firstFix = Completer<void>();
      try {
        await firstFix.future.timeout(firstFixTimeout);
      } on TimeoutException {
        throw const JourneyLocationException(
          JourneyLocationFailure.noFixReceived,
        );
      } finally {
        _firstFix = null;
      }
    } catch (_) {
      try {
        await _subscription?.cancel();
        _subscription = null;
        await _locationSource.stop();
      } finally {
        _session = await _repository.pause(
          id: session.id,
          userId: userId,
          at: _notBefore(session.recording.lastChangedAt!),
        );
      }
      rethrow;
    }
  }

  Future<LocalJourneySession> resume() async {
    final current = _requireSession(JourneyRecordingPhase.paused);
    lastError = null;
    if (_teardownPending) await _endStream();
    await _locationSource.start();
    try {
      _session = await _repository.resume(
        id: current.id,
        userId: _userId!,
        at: _notBefore(current.recording.lastChangedAt!),
      );
      _lastRecordedAt = null;
      _listen();
      return _session!;
    } catch (_) {
      try {
        await _locationSource.stop();
      } finally {
        final resumed = _session;
        if (resumed?.recording.phase == JourneyRecordingPhase.recording) {
          _session = await _repository.pause(
            id: resumed!.id,
            userId: _userId!,
            at: _notBefore(resumed.recording.lastChangedAt!),
          );
        }
      }
      rethrow;
    }
  }

  Future<LocalJourneySession> pause() async {
    final current = _requireSession(JourneyRecordingPhase.recording);
    try {
      await _endStream();
    } finally {
      _session = await _repository.pause(
        id: current.id,
        userId: _userId!,
        at: _notBefore(current.recording.lastChangedAt!),
      );
    }
    return _session!;
  }

  Future<LocalJourneySession> finish() async {
    final current = _session;
    if (current == null) throw StateError('No Journey is attached.');
    if (current.recording.phase == JourneyRecordingPhase.recording) {
      try {
        await _endStream();
      } catch (_) {
        _session = await _repository.pause(
          id: current.id,
          userId: _userId!,
          at: _notBefore(current.recording.lastChangedAt!),
        );
        rethrow;
      }
    }
    if (_teardownPending) await _endStream();
    final finished = await _repository.finish(
      id: current.id,
      userId: _userId!,
      at: _notBefore(current.recording.lastChangedAt!),
    );
    _session = null;
    _userId = null;
    return finished;
  }

  /// Lets go of the attached Journey without finishing it, e.g. when the
  /// signed-in account changes: a recording one is paused (saved for its
  /// owner to resume later) and the location stream stops.
  Future<void> detach() async {
    final current = _session;
    if (current == null) return;
    if (current.recording.phase == JourneyRecordingPhase.recording) {
      await pause();
    }
    if (_teardownPending) await _endStream();
    _session = null;
    _userId = null;
  }

  Future<void> _startStream() async {
    if (_teardownPending) await _endStream();
    await _locationSource.start();
    _lastRecordedAt = null;
    _listen();
  }

  void _listen() {
    _closing = false;
    _subscription = _locationSource.fixes.listen((fix) {
      if (!(_firstFix?.isCompleted ?? true)) _firstFix!.complete();
      if (_closing) return;
      final current = _session;
      final userId = _userId;
      if (current == null || userId == null) return;
      _writes = _writes
          .then<void>((_) async {
            try {
              final active = _session;
              if (active == null ||
                  active.id != current.id ||
                  active.recording.phase != JourneyRecordingPhase.recording) {
                return;
              }
              final previous = _lastRecordedAt;
              if (previous != null &&
                  fix.recordedAt.difference(previous) > missingFixGap) {
                _session = await _repository.splitSegment(
                  id: current.id,
                  userId: userId,
                  at: fix.recordedAt,
                );
              }
              await _repository.appendPoint(
                id: current.id,
                userId: userId,
                point: fix.inSegment(_session!.recording.segmentNumber),
              );
              _lastRecordedAt = fix.recordedAt;
            } on JourneyPointRejected {
              // Delayed or out-of-order fixes are not part of the route.
            }
          })
          .catchError(_streamFailed);
    }, onError: _streamFailed);
  }

  void _streamFailed(Object error, StackTrace stack) {
    lastError = error;
    if (_closing ||
        _session?.recording.phase != JourneyRecordingPhase.recording) {
      return;
    }
    unawaited(
      Future<void>(() async {
        try {
          await pause();
        } catch (pauseError) {
          lastError = pauseError;
        } finally {
          final paused = _session;
          if (paused?.recording.phase == JourneyRecordingPhase.paused) {
            onUnexpectedPause?.call(paused!);
          }
        }
      }),
    );
  }

  Future<void> _endStream() async {
    _closing = true;
    _canceling ??= _subscription?.cancel() ?? Future<void>.value();
    final canceled = await _bounded(
      'cancel the location stream',
      () => _canceling!,
    );
    if (canceled) {
      _subscription = null;
      _canceling = null;
    }
    final saved = await _bounded('save the last points', () => _writes);
    final stopped = canceled
        ? await _bounded('stop background location', _locationSource.stop)
        : false;
    _teardownPending = !canceled || !saved || !stopped;
    if (_teardownPending) throw const JourneyTeardownException();
  }

  Future<bool> _bounded(String what, Future<void> Function() step) async {
    try {
      await step().timeout(teardownTimeout);
      return true;
    } on TimeoutException {
      _logger.warning('Journey teardown: timed out trying to $what.');
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Journey teardown: failed to $what.',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return false;
  }

  LocalJourneySession _requireSession(JourneyRecordingPhase phase) {
    final current = _session;
    if (current == null || current.recording.phase != phase) {
      throw StateError('Journey is not ${phase.name}.');
    }
    return current;
  }

  DateTime _notBefore(DateTime previous) {
    final now = _clock();
    return now.isAfter(previous)
        ? now
        : previous.add(const Duration(milliseconds: 1));
  }
}
