// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One foreground location read for detection; null when unavailable.
/// Tests override it.

@ProviderFor(detectionLocationReader)
const detectionLocationReaderProvider = DetectionLocationReaderProvider._();

/// One foreground location read for detection; null when unavailable.
/// Tests override it.

final class DetectionLocationReaderProvider
    extends
        $FunctionalProvider<
          Future<AppLocationFix?> Function(),
          Future<AppLocationFix?> Function(),
          Future<AppLocationFix?> Function()
        >
    with $Provider<Future<AppLocationFix?> Function()> {
  /// One foreground location read for detection; null when unavailable.
  /// Tests override it.
  const DetectionLocationReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detectionLocationReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detectionLocationReaderHash();

  @$internal
  @override
  $ProviderElement<Future<AppLocationFix?> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<AppLocationFix?> Function() create(Ref ref) {
    return detectionLocationReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<AppLocationFix?> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<AppLocationFix?> Function()>(
        value,
      ),
    );
  }
}

String _$detectionLocationReaderHash() =>
    r'4e115d1015019c71a14961e2bc18bd2365568171';

/// Detection's foreground cycle (v1 `GeofenceLifecycleObserver`, moved out
/// of the widget): run on start, on resume and every 15 s while the app is
/// in front. Each run:
///
/// 1. reads one fix and, the first time, seeds the current county from it
///    (else the home county) and registers geofences;
/// 2. reconciles the current county from the fix (a crossing the OS
///    missed becomes a normal exit / enter);
/// 3. captures active candidates, then resolves any past the 2 h dwell;
/// 4. uploads the queue;
/// 5. re-registers the geofence window around the current county;
/// 6. offers the newest unseen crossing to the arrival sheet.
///
/// Before any of that it checks background location. Without it the
/// geofences are removed once, the queue still uploads, and the snapshot
/// says detection is paused (Home shows it) until access comes back.
///
/// The fix only decides the county and is never stored (doc 05). A
/// failure is logged and the next run retries.

@ProviderFor(DetectionController)
const detectionControllerProvider = DetectionControllerProvider._();

/// Detection's foreground cycle (v1 `GeofenceLifecycleObserver`, moved out
/// of the widget): run on start, on resume and every 15 s while the app is
/// in front. Each run:
///
/// 1. reads one fix and, the first time, seeds the current county from it
///    (else the home county) and registers geofences;
/// 2. reconciles the current county from the fix (a crossing the OS
///    missed becomes a normal exit / enter);
/// 3. captures active candidates, then resolves any past the 2 h dwell;
/// 4. uploads the queue;
/// 5. re-registers the geofence window around the current county;
/// 6. offers the newest unseen crossing to the arrival sheet.
///
/// Before any of that it checks background location. Without it the
/// geofences are removed once, the queue still uploads, and the snapshot
/// says detection is paused (Home shows it) until access comes back.
///
/// The fix only decides the county and is never stored (doc 05). A
/// failure is logged and the next run retries.
final class DetectionControllerProvider
    extends $NotifierProvider<DetectionController, DetectionSnapshot> {
  /// Detection's foreground cycle (v1 `GeofenceLifecycleObserver`, moved out
  /// of the widget): run on start, on resume and every 15 s while the app is
  /// in front. Each run:
  ///
  /// 1. reads one fix and, the first time, seeds the current county from it
  ///    (else the home county) and registers geofences;
  /// 2. reconciles the current county from the fix (a crossing the OS
  ///    missed becomes a normal exit / enter);
  /// 3. captures active candidates, then resolves any past the 2 h dwell;
  /// 4. uploads the queue;
  /// 5. re-registers the geofence window around the current county;
  /// 6. offers the newest unseen crossing to the arrival sheet.
  ///
  /// Before any of that it checks background location. Without it the
  /// geofences are removed once, the queue still uploads, and the snapshot
  /// says detection is paused (Home shows it) until access comes back.
  ///
  /// The fix only decides the county and is never stored (doc 05). A
  /// failure is logged and the next run retries.
  const DetectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detectionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detectionControllerHash();

  @$internal
  @override
  DetectionController create() => DetectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DetectionSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DetectionSnapshot>(value),
    );
  }
}

String _$detectionControllerHash() =>
    r'716600fb246b6fe73e647c3a9f5f71eb9f16f15b';

/// Detection's foreground cycle (v1 `GeofenceLifecycleObserver`, moved out
/// of the widget): run on start, on resume and every 15 s while the app is
/// in front. Each run:
///
/// 1. reads one fix and, the first time, seeds the current county from it
///    (else the home county) and registers geofences;
/// 2. reconciles the current county from the fix (a crossing the OS
///    missed becomes a normal exit / enter);
/// 3. captures active candidates, then resolves any past the 2 h dwell;
/// 4. uploads the queue;
/// 5. re-registers the geofence window around the current county;
/// 6. offers the newest unseen crossing to the arrival sheet.
///
/// Before any of that it checks background location. Without it the
/// geofences are removed once, the queue still uploads, and the snapshot
/// says detection is paused (Home shows it) until access comes back.
///
/// The fix only decides the county and is never stored (doc 05). A
/// failure is logged and the next run retries.

abstract class _$DetectionController extends $Notifier<DetectionSnapshot> {
  DetectionSnapshot build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DetectionSnapshot, DetectionSnapshot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DetectionSnapshot, DetectionSnapshot>,
              DetectionSnapshot,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
