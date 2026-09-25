import 'dart:async';

import '../data/local_journey_repository.dart';
import '../domain/journey_fix.dart';
import '../domain/journey_recording.dart';

/// Drives an already-authorized local session; creating one is left to the
/// future server-verified Pro start flow.
class JourneyCapture {
  JourneyCapture({
    required LocalJourneyRepository repository,
    required JourneyLocationSource locationSource,
    DateTime Function()? clock,
  }) : _repository = repository,
       _locationSource = locationSource,
       _clock = clock ?? DateTime.now;

  final LocalJourneyRepository _repository;
  final JourneyLocationSource _locationSource;
  final DateTime Function() _clock;

  LocalJourneySession? _session;
  String? _userId;
  StreamSubscription<JourneyFix>? _subscription;
  Future<void> _writes = Future.value();
  bool _closing = false;
  Object? lastError;

  LocalJourneySession? get session => _session;

  /// A process restart cannot recover locations missed while Dart was dead.
  /// Pause the saved session, so the next Resume begins a new route segment.
  Future<LocalJourneySession?> recover(String userId) async {
    if (_session != null) throw StateError('Capture is already attached.');
    final saved = await _repository.activeSession(userId);
    if (saved == null) return null;
    _userId = userId;
    _session = saved.recording.phase == JourneyRecordingPhase.recording
        ? await _repository.pause(
            id: saved.id,
            userId: userId,
            at: _notBefore(saved.recording.lastChangedAt!),
          )
        : saved;
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
    await _locationSource.start();
    try {
      _session = await _repository.resume(
        id: current.id,
        userId: _userId!,
        at: _notBefore(current.recording.lastChangedAt!),
      );
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
    final finished = await _repository.finish(
      id: current.id,
      userId: _userId!,
      at: _notBefore(current.recording.lastChangedAt!),
    );
    _session = null;
    _userId = null;
    return finished;
  }

  Future<void> _startStream() async {
    await _locationSource.start();
    _listen();
  }

  void _listen() {
    _closing = false;
    _subscription = _locationSource.fixes.listen((fix) {
      if (_closing) return;
      final current = _session;
      final userId = _userId;
      if (current == null || userId == null) return;
      final point = fix.inSegment(current.recording.segmentNumber);
      _writes = _writes
          .then<void>((_) async {
            try {
              await _repository.appendPoint(
                id: current.id,
                userId: userId,
                point: point,
              );
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
        }
      }),
    );
  }

  Future<void> _endStream() async {
    _closing = true;
    await _subscription?.cancel();
    _subscription = null;
    await _writes;
    await _locationSource.stop();
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
