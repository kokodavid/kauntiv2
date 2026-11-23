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
              await _endStream();
              final current = _requireSession(JourneyRecordingPhase.recording);
              await _startLocationSource(current.id, _userId!);
              _splitOnNextFix = true;
              _listen();
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
              _recordDiagnostic('journey_location_recovery_failed', {
                'attempt': attempt,
              });
            }
          }
          shouldNotifyPause = true;
          final pauseSettings = await _readDeviceSettings();
          if (pauseSettings != null) {
            _quality = _quality.copyWith(settingsAtPause: pauseSettings);
          }
          try {
            await pause(reason: JourneyPauseReason.locationLost);
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
