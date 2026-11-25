import 'dart:async';
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../services/app_logger.dart';
import '../../auth/application/auth_providers.dart';
import '../data/county_tracking_location_source.dart';
import '../data/county_tracking_preference.dart';
import 'detection_providers.dart';
import 'trip_fix_ingest.dart';

part 'county_tracking.g.dart';

@Riverpod(keepAlive: true)
CountyTrackingPreference countyTrackingPreference(Ref ref) =>
    const CountyTrackingPreference();

@Riverpod(keepAlive: true)
CountyTrackingSource countyTrackingSource(Ref ref) =>
    DeviceCountyTrackingSource();

/// "Accurate county times", an opt-in setting (off by default). While it is
/// on, low-power background location tells county detection where the phone
/// is every kilometre or so, instead of waiting for a geofence event that
/// can arrive late or not at all. The cost is a little battery and, on
/// Android, a quiet notification while it runs.
///
/// A recording Trip already feeds detection its own fixes and owns the
/// phone's location settings, so this steps aside while one records and
/// starts again when it ends ([sync], called by the app layer).
///
/// State: whether the user turned it on.
@Riverpod(keepAlive: true)
class CountyTracking extends _$CountyTracking {
  static const _logger = AppLogger.detection();

  StreamSubscription<CountyTrackingFix>? _subscription;
  bool _running = false;
  bool _tripRecording = false;
  Future<void> _queue = Future.value();

  late final TripFixIngest _ingest = TripFixIngest(
    () => ref.read(detectionRepositoryProvider),
    isSignedIn: () => ref.read(currentUserIdProvider)() != null,
    minGap: const Duration(seconds: 60),
    maxAge: const Duration(minutes: 5),
  );

  @override
  Future<bool> build() async {
    ref.onDispose(() => _subscription?.cancel());
    return ref.read(countyTrackingPreferenceProvider).enabled();
  }

  /// Turns it on or off. Turning it on needs location allowed all the
  /// time; returns false (and stays off) when that isn't granted.
  Future<bool> setEnabled(bool on) async {
    if (on && !await ref.read(countyTrackingSourceProvider).canRun()) {
      return false;
    }
    await ref.read(countyTrackingPreferenceProvider).setEnabled(on);
    state = AsyncData(on);
    await sync(tripRecording: _tripRecording);
    return true;
  }

  /// Starts or stops the updates to match the setting, the account and
  /// whether a Trip is recording. Calls run one at a time.
  Future<void> sync({required bool tripRecording}) {
    _tripRecording = tripRecording;
    return _queue = _queue.then((_) => _apply()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      _logger.warning(
        'Accurate county times could not update.',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  /// Back to the low-power settings when the app goes to the background.
  Future<void> reapplySettings() async {
    if (!_running) return;
    try {
      await ref.read(countyTrackingSourceProvider).applySettings();
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Accurate county times settings not reapplied.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _apply() async {
    final enabled = (await future) == true;
    final signedIn = ref.read(currentUserIdProvider)() != null;
    final want = enabled && signedIn && !_tripRecording;
    if (want == _running) return;
    final source = ref.read(countyTrackingSourceProvider);
    if (!want) {
      await _subscription?.cancel();
      _subscription = null;
      _running = false;
      // A recording Trip owns background location now: leave it running.
      if (!_tripRecording) await source.stop();
      return;
    }
    final fixes = await source.start();
    if (fixes == null) return;
    _subscription = fixes.listen(
      (fix) => unawaited(
        _ingest.offer(
          latitude: fix.latitude,
          longitude: fix.longitude,
          at: fix.at,
          minimumInsideDistanceMeters: math.max(
            CountyBoundaryResolver.boundaryHysteresisMeters,
            fix.accuracyMeters,
          ),
        ),
      ),
      onError: (Object error, StackTrace stackTrace) => _logger.warning(
        'Accurate county times location stream failed.',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    _running = true;
  }
}
