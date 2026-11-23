import '../domain/journey_pause_reason.dart';
import '../domain/journey_recording.dart';

class LocalJourneySession {
  const LocalJourneySession({
    required this.id,
    required this.recording,
    this.pauseReason,
  });

  final String id;
  final JourneyRecording recording;

  /// Why the Trip is paused; null while it is not paused.
  final JourneyPauseReason? pauseReason;
}

class JourneyPointRejected implements Exception {
  const JourneyPointRejected();
}
