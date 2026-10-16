import 'dart:async';

import '../../../services/app_logger.dart';
import '../data/local_journey_repository.dart';
import '../domain/journey_fix.dart';
import '../domain/journey_recording.dart';

part 'journey_capture_lifecycle.dart';

/// Drives a server-authorized local session and its location stream.
class JourneyCapture {
  JourneyCapture({
    required LocalJourneyRepository repository,
    required JourneyLocationSource locationSource,
    DateTime Function()? clock,
    this.teardownTimeout = const Duration(seconds: 4),
    this.firstFixTimeout = const Duration(seconds: 20),
    this.streamRecoveryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ],
    this.onDiagnosticEvent,
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

  /// Delays between attempts to restart an interrupted location stream.
  final List<Duration> streamRecoveryDelays;

  final Future<void> Function(String, Map<String, Object?>)? onDiagnosticEvent;

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
  bool _recoveringStream = false;
  bool _splitOnNextFix = false;
  Object? lastError;
  void Function(LocalJourneySession)? onUnexpectedPause;

  LocalJourneySession? get session => _session;
  String? get ownerUserId => _userId;

  Future<void> _startStream() async {
    if (_teardownPending) await _endStream();
    final current = _requireSession(JourneyRecordingPhase.recording);
    final userId = _userId;
    if (userId == null) throw StateError('Capture has no owner.');
    await _startLocationSource(current.id, userId);
    _lastRecordedAt = null;
    _listen();
  }

  void _listen() {
    _closing = false;
    _subscription = _locationSource.fixes.listen(
      (fix) {
        if (_closing) return;
        final current = _session;
        final userId = _userId;
        if (current == null || userId == null) return;
        // Only let a fix that appendPoint below would actually accept
        // complete attachStarted's first-fix wait. The location source can
        // hand back a cached last-known fix the instant the stream opens,
        // before any live GPS reading arrives - it passes the source's own
        // accuracy/mock checks, but its [recordedAt] predates the Trip's
        // start, so appendPoint rejects it as a JourneyPointRejected a few
        // lines down. Completing here regardless of that used to let
        // attachStarted resolve - and the UI navigate to the recording
        // screen - on a fix that was never actually going to end up in the
        // route, leaving "Waiting for your location" stuck with nothing to
        // clear it until a genuinely fresh fix happened to arrive.
        final isStale = fix.recordedAt.isBefore(
          current.recording.lastChangedAt!,
        );
        if (!isStale && !(_firstFix?.isCompleted ?? true)) {
          _firstFix!.complete();
        }
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
                final gap = previous == null
                    ? null
                    : fix.recordedAt.difference(previous);
                if (_splitOnNextFix || (gap != null && gap > missingFixGap)) {
                  _recordDiagnostic('journey_segment_gap', {
                    if (gap != null) 'gap_ms': gap.inMilliseconds,
                    'threshold_ms': missingFixGap.inMilliseconds,
                  });
                  _session = await _repository.splitSegment(
                    id: current.id,
                    userId: userId,
                    at: fix.recordedAt,
                  );
                  _splitOnNextFix = false;
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
      },
      onError: _streamFailed,
      onDone: _streamClosed,
    );
  }

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
    var shouldNotifyPause = false;
    unawaited(
      Future<void>(() async {
        try {
          for (var index = 0; index < streamRecoveryDelays.length; index++) {
            final delay = streamRecoveryDelays[index];
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
              _recordDiagnostic('journey_location_recovered', {});
              return;
            } catch (error) {
              lastError = error;
              _recordDiagnostic('journey_location_recovery_failed', {
                'attempt': index + 1,
              });
            }
          }
          shouldNotifyPause = true;
          try {
            await pause();
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
    final stopped = await _bounded(
      'stop background location',
      _locationSource.stop,
    );
    _recordDiagnostic('journey_location_stopped', {
      'native_stop_succeeded': stopped,
    });
    final saved = await _bounded('save the last points', () => _writes);
    _teardownPending = !canceled || !saved || !stopped;
    if (_teardownPending) throw const JourneyTeardownException();
  }

  Future<void> _startLocationSource(String id, String userId) async {
    final mode = await _repository.transportMode(id, userId);
    await _locationSource.start(mode: mode);
    _recordDiagnostic('journey_location_started', {
      'transport_mode': mode?.storageValue ?? 'unknown',
    });
  }

  void _recordDiagnostic(String event, Map<String, Object?> data) {
    final record = onDiagnosticEvent;
    if (record != null) unawaited(record(event, data));
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
