enum JourneyRecordingPhase { idle, recording, paused, completed }

class JourneyRecording {
  const JourneyRecording._({
    required this.phase,
    this.startedAt,
    this.pausedAt,
    this.endedAt,
    this.lastChangedAt,
    this.segmentNumber = 0,
  });

  const JourneyRecording.idle() : this._(phase: JourneyRecordingPhase.idle);

  final JourneyRecordingPhase phase;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? endedAt;
  final DateTime? lastChangedAt;
  final int segmentNumber;

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
    );
  }
}
