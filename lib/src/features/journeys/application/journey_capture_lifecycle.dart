part of 'journey_capture.dart';

extension JourneyCaptureLifecycle on JourneyCapture {
  /// A process restart cannot recover locations missed while Dart was dead.
  /// Pause the saved session, so the next Resume begins a new route segment.
  Future<LocalJourneySession?> recover(String userId) async {
    if (_session != null) throw StateError('Capture is already attached.');
    _teardownPending = !await _bounded(
      'stop stale background location',
      _locationSource.stop,
    );
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
    await _startLocationSource(current.id, _userId!);
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

  /// Releases the attached Journey without finishing it when the account
  /// changes, pausing a recording one so its owner can resume it later.
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
}
