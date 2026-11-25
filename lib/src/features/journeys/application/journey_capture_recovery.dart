part of 'journey_capture.dart';

extension JourneyCaptureRecovery on JourneyCapture {
  void _streamFailed(Object error, StackTrace stack) {
    lastError = error;
    _recoverStream();
  }

  void _streamClosed() {
    if (_closing ||
        _session?.recording.phase != JourneyRecordingPhase.recording) {
      return;
    }
    lastError = StateError('Location stream closed unexpectedly.');
    _recoverStream();
  }

  void _recoverStream() {
    if (_closing ||
        _recoveringStream ||
        _session?.recording.phase != JourneyRecordingPhase.recording) {
      return;
    }
    _recoveringStream = true;
    _quality = _quality.copyWith(streamLosses: _quality.streamLosses + 1);
    var shouldNotifyPause = false;
    var recovered = false;
    if (maxRecoveryTime > Duration.zero) {
      unawaited(
        Future<void>.delayed(maxRecoveryTime, () async {
          if (recovered ||
              !_recoveringStream ||
              _session?.recording.phase != JourneyRecordingPhase.recording) {
            return;
          }
          shouldNotifyPause = true;
          try {
            final pauseSettings = await _readDeviceSettings();
            if (pauseSettings != null) {
              _quality = _quality.copyWith(settingsAtPause: pauseSettings);
            }
            await _pauseAfterRecoveryDeadline();
            final current = _session;
            if (current?.recording.phase == JourneyRecordingPhase.paused) {
              onUnexpectedPause?.call(current!);
              shouldNotifyPause = false;
            }
          } catch (error) {
            lastError = error;
          }
        }),
      );
    }
    unawaited(
      Future<void>(() async {
        try {
          final stopwatch = Stopwatch()..start();
          var attempt = 0;
          while (true) {
            final Duration delay;
            if (attempt < streamRecoveryDelays.length) {
              delay = streamRecoveryDelays[attempt];
            } else if (stopwatch.elapsed + recoveryRepeatDelay <=
                maxRecoveryTime) {
              delay = recoveryRepeatDelay;
            } else {
              break;
            }
            attempt++;
            await Future<void>.delayed(delay);
            if (_closing ||
                _session?.recording.phase != JourneyRecordingPhase.recording) {
              return;
            }
            try {
              final remaining = maxRecoveryTime - stopwatch.elapsed;
              await _endStream(
                timeout: remaining.isNegative ? Duration.zero : remaining,
              );
              final current = _requireSession(JourneyRecordingPhase.recording);
              await _startLocationSource(current.id, _userId!);
              _splitOnNextFix = true;
              _listen();
              recovered = true;
              _recordDiagnostic('journey_location_recovered', {
                'attempts': attempt,
                'lost_ms': stopwatch.elapsed.inMilliseconds,
              });
              _quality = _quality.copyWith(
                streamRecoveries: _quality.streamRecoveries + 1,
                lostMillis:
                    _quality.lostMillis + stopwatch.elapsed.inMilliseconds,
              );
              await _flushQuality();
              return;
            } catch (error) {
              lastError = error;
              // A failed restart closes the old stream, but recovery itself
              // must remain active for the next retry or deadline watchdog.
              _closing = false;
              _recordDiagnostic('journey_location_recovery_failed', {
                'attempt': attempt,
              });
            }
          }
          shouldNotifyPause = true;
          final remaining = maxRecoveryTime - stopwatch.elapsed;
          final pauseSettings = await _readDeviceSettings();
          if (pauseSettings != null) {
            _quality = _quality.copyWith(settingsAtPause: pauseSettings);
          }
          try {
            await pause(
              reason: JourneyPauseReason.locationLost,
              teardownTimeoutOverride: remaining.isNegative
                  ? Duration.zero
                  : remaining,
            );
          } catch (error) {
            lastError = error;
          }
        } finally {
          _recoveringStream = false;
          final current = _session;
          if (shouldNotifyPause &&
              current?.recording.phase == JourneyRecordingPhase.paused) {
            onUnexpectedPause?.call(current!);
          }
        }
      }),
    );
  }

  /// Persist the safety pause without waiting for a native stream that may
  /// have stopped responding. Cleanup is deliberately best-effort; the next
  /// resume/attach will retry any pending native teardown.
  Future<void> _pauseAfterRecoveryDeadline() async {
    final current = _session;
    final userId = _userId;
    if (current == null ||
        userId == null ||
        current.recording.phase != JourneyRecordingPhase.recording) {
      return;
    }
    _closing = true;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    unawaited(_locationSource.stop());
    final pausedAt = _notBefore(current.recording.lastChangedAt!);
    _session = LocalJourneySession(
      id: current.id,
      recording: current.recording.pause(pausedAt),
      pauseReason: JourneyPauseReason.locationLost,
    );
    try {
      _session = await _repository.pause(
        id: current.id,
        userId: userId,
        at: pausedAt,
        reason: JourneyPauseReason.locationLost,
      );
    } on Object catch (error) {
      lastError = error;
    }
    _quality = _quality.withPause(JourneyPauseReason.locationLost);
    await _flushQuality();
  }

  /// Saves quality counts locally without interrupting Trip recording.
  Future<void> _flushQuality() async {
    final id = _session?.id;
    final userId = _userId;
    if (id == null || userId == null) return;
    try {
      await _repository.saveQuality(id, userId, _quality);
    } on Object catch (error, stackTrace) {
      JourneyCapture._logger.warning(
        'Journey quality not saved.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<JourneyDeviceSettings?> _readDeviceSettings() async {
    final source = deviceSettings;
    if (source == null) return null;
    try {
      return await source.read().timeout(const Duration(seconds: 2));
    } on Object {
      return null;
    }
  }
}
