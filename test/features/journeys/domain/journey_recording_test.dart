import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_point.dart';
import 'package:kaunti47_v2/src/features/journeys/domain/journey_recording.dart';

void main() {
  final start = DateTime.utc(2026, 9, 25, 10);

  test('pause and resume create a separate route segment', () {
    final first = const JourneyRecording.idle().start(start);
    final paused = first.pause(start.add(const Duration(minutes: 5)));
    final resumed = paused.resume(start.add(const Duration(minutes: 8)));

    expect(resumed.phase, JourneyRecordingPhase.recording);
    expect(resumed.segmentNumber, 1);
    expect(resumed.startedAt, start);
    expect(
      resumed.finish(start.add(const Duration(minutes: 12))).endedAt,
      start.add(const Duration(minutes: 12)),
    );
  });

  test('a completed Journey cannot restart or resume', () {
    final completed = const JourneyRecording.idle()
        .start(start)
        .finish(start.add(const Duration(minutes: 1)));

    expect(() => completed.start(start), throwsStateError);
    expect(() => completed.resume(start), throwsStateError);
  });

  test('a delayed transition cannot move recording time backwards', () {
    final resumed = const JourneyRecording.idle()
        .start(start)
        .pause(start.add(const Duration(minutes: 5)))
        .resume(start.add(const Duration(minutes: 8)));

    expect(
      () => resumed.pause(start.add(const Duration(minutes: 7))),
      throwsStateError,
    );
    expect(
      () => resumed.finish(start.add(const Duration(minutes: 7))),
      throwsStateError,
    );
  });

  test('invalid coordinates and accuracy are rejected', () {
    expect(
      () => JourneyPoint(
        recordedAt: start,
        latitude: 91,
        longitude: 37,
        accuracyMeters: 5,
        segmentNumber: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => JourneyPoint(
        recordedAt: start,
        latitude: -1,
        longitude: 37,
        accuracyMeters: -1,
        segmentNumber: 0,
      ),
      throwsArgumentError,
    );
  });
}
