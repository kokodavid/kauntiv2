import 'dart:async';

import '../../../services/app_logger.dart';
import '../data/local_journey_repository.dart';
import '../domain/journey_device_settings.dart';
import '../domain/journey_fix.dart';
import '../domain/journey_pause_reason.dart';
import '../domain/journey_quality.dart';
import '../domain/journey_recording.dart';
import '../domain/journey_spike_filter.dart';

part 'journey_capture_lifecycle.dart';
part 'journey_capture_recovery.dart';

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
    this.recoveryRepeatDelay = const Duration(seconds: 30),
    this.maxRecoveryTime = Duration.zero,
    this.deviceSettings,
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

  /// Once [streamRecoveryDelays] are used up, restart attempts carry on at
  /// this interval until [maxRecoveryTime] has passed since the stream was
  /// lost. A Trip that loses location (power saving, a tunnel, a weak
  /// signal) stays recording through that time instead of pausing itself.
  final Duration recoveryRepeatDelay;

  /// How long to keep trying before the Trip pauses itself with
  /// [JourneyPauseReason.locationLost]. Zero means only the delays in
  /// [streamRecoveryDelays] are tried.
  final Duration maxRecoveryTime;

  /// Reads the phone's power settings, for the pre-trip check and the
  /// quality summary. Optional: without it neither is available.
  final JourneyDeviceSettingsSource? deviceSettings;

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

  /// Fixes thrown away as GPS spikes, and real jumps accepted after a
  /// second fix confirmed them, since this capture was created.
  int spikesDropped = 0;
  int jumpsAccepted = 0;

  /// How well this Trip is recording; saved with the Trip and sent when it
  /// uploads. Counts only.
  JourneyQuality _quality = const JourneyQuality();
  JourneyQuality get quality => _quality;

  JourneySpikeFilter _spikeFilter = JourneySpikeFilter(
    maxSpeedMetersPerSecond: null,
  );
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
                  _spikeFilter.reset();
                  if (gap != null && gap > missingFixGap) {
                    _quality = _quality.copyWith(
                      gaps: _quality.gaps + 1,
                      gapMillis: _quality.gapMillis + gap.inMilliseconds,
                    );
                    await _flushQuality();
                  }
                }
                final verdict = _spikeFilter.judge(fix);
                if (verdict.spikesDropped > 0) {
                  spikesDropped += verdict.spikesDropped;
                  _quality = _quality.copyWith(
                    spikesDropped:
                        _quality.spikesDropped + verdict.spikesDropped,
                  );
                  _recordDiagnostic('journey_spike_dropped', {
                    'count': verdict.spikesDropped,
                  });
                  await _flushQuality();
                }
                for (var index = 0; index < verdict.accepted.length; index++) {
                  final accepted = verdict.accepted[index];
                  if (index == 0 && verdict.startsNewSegment) {
                    // Two fixes agree on a far-away position: a real jump
                    // (tunnel, long signal loss), so no line is drawn across.
                    jumpsAccepted++;
                    _quality = _quality.copyWith(
                      jumpsAccepted: _quality.jumpsAccepted + 1,
                    );
                    _recordDiagnostic('journey_jump_accepted', {});
                    await _flushQuality();
                    _session = await _repository.splitSegment(
                      id: current.id,
                      userId: userId,
                      at: accepted.recordedAt,
                    );
                  }
                  await _repository.appendPoint(
                    id: current.id,
                    userId: userId,
                    point: accepted.inSegment(
                      _session!.recording.segmentNumber,
                    ),
                  );
                  _lastRecordedAt = accepted.recordedAt;
                  _quality = _quality.copyWith(
                    fixesAccepted: _quality.fixesAccepted + 1,
                  );
                }
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
    // A fresh filter for every stream start: a resume or a restart begins a
    // new segment, so nothing from before it should be compared against.
    _spikeFilter = JourneySpikeFilter(
      maxSpeedMetersPerSecond: mode?.maxSpeedMetersPerSecond,
    );
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
