import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/device_motion_source.dart';
import '../domain/journey_recording.dart';
import '../domain/motion_rules.dart';
import 'journey_recorder.dart';

part 'device_motion.g.dart';

@Riverpod(keepAlive: true)
DeviceMotionSource deviceMotionSource(Ref ref) => DeviceMotionSource();

/// A Trip is recording (not paused). Its own provider so listeners rebuild
/// only when this flips, not on every recorder change.
@riverpod
bool isJourneyRecording(Ref ref) =>
    ref.watch(journeyRecorderProvider)?.recording.phase ==
    JourneyRecordingPhase.recording;

/// Whether the phone is moving, for Home. Watch it only while Home is on
/// screen: it holds a location stream open and closes it when nobody
/// listens. While a Trip records, the recorder owns location and this stays
/// [MotionState.unknown].
@riverpod
Stream<MotionState> deviceMotion(Ref ref) {
  final recording = ref.watch(isJourneyRecordingProvider);
  final controller = StreamController<MotionState>();
  ref.onDispose(controller.close);
  if (recording) return controller.stream;

  final tracker = MotionTracker();
  var last = MotionState.unknown;
  void emit(MotionState next) {
    if (next == last || controller.isClosed) return;
    last = next;
    controller.add(next);
  }

  StreamSubscription<MotionFix>? subscription;
  ref.onDispose(() => subscription?.cancel());
  final timer = Timer.periodic(
    const Duration(seconds: 10),
    (_) => emit(tracker.tick(DateTime.now())),
  );
  ref.onDispose(timer.cancel);

  unawaited(() async {
    final fixes = await ref.read(deviceMotionSourceProvider).open();
    if (fixes == null || controller.isClosed) return;
    subscription = fixes.listen(
      (fix) => emit(tracker.addFix(speed: fix.speed, at: fix.at)),
      onError: (Object _) {},
    );
  }());
  return controller.stream;
}
