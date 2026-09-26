enum JourneyRecordingPhase { idle, recording, paused, completed }

class JourneyRecording {
  const JourneyRecording._({
    required this.phase,
    this.startedAt,
    this.pausedAt,
    this.endedAt,
    this.lastChangedAt,
    this.segmentNumber = 0,
    this.pausedTotal = Duration.zero,
  });

  const JourneyRecording.idle() : this._(phase: JourneyRecordingPhase.idle);

  factory JourneyRecording.restore({
    required JourneyRecordingPhase phase,
    required DateTime startedAt,
    required DateTime lastChangedAt,
    required int segmentNumber,
    DateTime? pausedAt,
    DateTime? endedAt,
    Duration pausedTotal = Duration.zero,
  }) {
    if (phase == JourneyRecordingPhase.idle ||
        segmentNumber < 0 ||
        pausedTotal.isNegative ||
        pausedTotal > lastChangedAt.difference(startedAt) ||
        lastChangedAt.isBefore(startedAt) ||
        (phase == JourneyRecordingPhase.paused) != (pausedAt != null) ||
        (phase == JourneyRecordingPhase.completed) != (endedAt != null) ||
        (pausedAt != null && !pausedAt.isAtSameMomentAs(lastChangedAt)) ||
        (endedAt != null &&
            (!endedAt.isAtSameMomentAs(lastChangedAt) ||
                !endedAt.isAfter(startedAt)))) {
      throw ArgumentError('Invalid saved Journey state.');
    }
    return JourneyRecording._(
      phase: phase,
      startedAt: startedAt,
      pausedAt: pausedAt,
      endedAt: endedAt,
      lastChangedAt: lastChangedAt,
      segmentNumber: segmentNumber,
      pausedTotal: pausedTotal,
    );
  }

  final JourneyRecordingPhase phase;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? endedAt;
  final DateTime? lastChangedAt;
  final int segmentNumber;

  /// Time spent paused in earlier pauses (the current one, if paused, is
  /// counted from [pausedAt]).
  final Duration pausedTotal;

  /// Time spent recording: start to [now] (or the pause, or the end),
  /// minus pauses. The live clock stands still while paused.
  Duration recordedTime(DateTime now) {
    final start = startedAt;
    if (start == null) return Duration.zero;
    final until = endedAt ?? pausedAt ?? now;
    final time = until.difference(start) - pausedTotal;
    return time.isNegative ? Duration.zero : time;
  }

  JourneyRecording start(DateTime at) {
    if (phase != JourneyRecordingPhase.idle) {
      throw StateError('A Journey can only start once.');
    }
    return JourneyRecording._(
      phase: JourneyRecordingPhase.recording,
      startedAt: at,
      lastChangedAt: at,
    );
  }

  JourneyRecording pause(DateTime at) {
    if (phase != JourneyRecordingPhase.recording ||
        at.isBefore(lastChangedAt!)) {
      throw StateError('Only an active Journey can be paused.');
    }
    return JourneyRecording._(
      phase: JourneyRecordingPhase.paused,
      startedAt: startedAt,
      pausedAt: at,
      lastChangedAt: at,
      segmentNumber: segmentNumber,
      pausedTotal: pausedTotal,
    );
  }

  JourneyRecording resume(DateTime at) {
    if (phase != JourneyRecordingPhase.paused || at.isBefore(lastChangedAt!)) {
      throw StateError('Only a paused Journey can resume.');
    }
    return JourneyRecording._(
      phase: JourneyRecordingPhase.recording,
      startedAt: startedAt,
      lastChangedAt: at,
      segmentNumber: segmentNumber + 1,
      pausedTotal: pausedTotal + at.difference(pausedAt!),
    );
  }

  JourneyRecording splitAt(DateTime at) {
    if (phase != JourneyRecordingPhase.recording ||
        at.isBefore(lastChangedAt!)) {
      throw StateError('Only an active Journey can start a new segment.');
    }
    return JourneyRecording._(
      phase: JourneyRecordingPhase.recording,
      startedAt: startedAt,
      lastChangedAt: at,
      segmentNumber: segmentNumber + 1,
      pausedTotal: pausedTotal,
    );
  }

  JourneyRecording finish(DateTime at) {
    if ((phase != JourneyRecordingPhase.recording &&
            phase != JourneyRecordingPhase.paused) ||
        !at.isAfter(startedAt!) ||
        at.isBefore(lastChangedAt!)) {
      throw StateError('Only a started Journey can finish.');
    }
    return JourneyRecording._(
      phase: JourneyRecordingPhase.completed,
      startedAt: startedAt,
      endedAt: at,
      lastChangedAt: at,
      segmentNumber: segmentNumber,
      // Stopping while paused: that last pause counts too.
      pausedTotal: pausedAt == null
          ? pausedTotal
          : pausedTotal + at.difference(pausedAt!),
    );
  }
}
