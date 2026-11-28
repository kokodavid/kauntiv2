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
          Future<AppLocationReading?> Function(),
          Future<AppLocationReading?> Function(),
          Future<AppLocationReading?> Function()
        >
    with $Provider<Future<AppLocationReading?> Function()> {
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
  $ProviderElement<Future<AppLocationReading?> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<AppLocationReading?> Function() create(Ref ref) {
    return detectionLocationReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<AppLocationReading?> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Future<AppLocationReading?> Function()>(value),
    );
  }
}

String _$detectionLocationReaderHash() =>
    r'501dbed01193796f09a1fd3a2001f4aea1f327c2';

/// Detection's foreground cycle (v1 `GeofenceLifecycleObserver`, moved out
/// of the widget): run on start, on resume and every 15 s while the app is
/// in front. Hardware location is reconciled less often by the lifecycle.
/// Each run:
///
/// 1. optionally reads a fix and, the first time, seeds the current county
///    from it (else the home county) and registers geofences;
/// 2. when a fix was read, reconciles the current county (an OS-missed
///    crossing becomes a normal exit / enter);
/// 3. captures active candidates, then resolves any past the 2 h dwell;
/// 4. uploads the queue;
/// 5. refreshes the geofence window when a hardware fix was reconciled;
/// 6. offers the newest unseen crossing to the arrival sheet.
///
/// Before any of that it checks permission. Without background location
/// the geofences are removed once but the cycle carries on: a fix is read,
/// the county reconciled and dwell checked, so a visit is still recorded
/// when the app is open. The snapshot flags it so Home can offer "Always".
/// With no location permission at all nothing is read; the queue still
/// uploads and Home says detection is off.
///
/// The fix only decides the county and is never stored (doc 05). A
/// failure is logged and the next run retries.

@ProviderFor(DetectionController)
const detectionControllerProvider = DetectionControllerProvider._();

/// Detection's foreground cycle (v1 `GeofenceLifecycleObserver`, moved out
/// of the widget): run on start, on resume and every 15 s while the app is
/// in front. Hardware location is reconciled less often by the lifecycle.
/// Each run:
///
/// 1. optionally reads a fix and, the first time, seeds the current county
///    from it (else the home county) and registers geofences;
/// 2. when a fix was read, reconciles the current county (an OS-missed
///    crossing becomes a normal exit / enter);
/// 3. captures active candidates, then resolves any past the 2 h dwell;
/// 4. uploads the queue;
/// 5. refreshes the geofence window when a hardware fix was reconciled;
/// 6. offers the newest unseen crossing to the arrival sheet.
///
/// Before any of that it checks permission. Without background location
/// the geofences are removed once but the cycle carries on: a fix is read,
/// the county reconciled and dwell checked, so a visit is still recorded
/// when the app is open. The snapshot flags it so Home can offer "Always".
/// With no location permission at all nothing is read; the queue still
/// uploads and Home says detection is off.
///
/// The fix only decides the county and is never stored (doc 05). A
/// failure is logged and the next run retries.
final class DetectionControllerProvider
    extends $NotifierProvider<DetectionController, DetectionSnapshot> {
  /// Detection's foreground cycle (v1 `GeofenceLifecycleObserver`, moved out
  /// of the widget): run on start, on resume and every 15 s while the app is
  /// in front. Hardware location is reconciled less often by the lifecycle.
  /// Each run:
  ///
  /// 1. optionally reads a fix and, the first time, seeds the current county
  ///    from it (else the home county) and registers geofences;
  /// 2. when a fix was read, reconciles the current county (an OS-missed
  ///    crossing becomes a normal exit / enter);
  /// 3. captures active candidates, then resolves any past the 2 h dwell;
  /// 4. uploads the queue;
  /// 5. refreshes the geofence window when a hardware fix was reconciled;
  /// 6. offers the newest unseen crossing to the arrival sheet.
  ///
  /// Before any of that it checks permission. Without background location
  /// the geofences are removed once but the cycle carries on: a fix is read,
  /// the county reconciled and dwell checked, so a visit is still recorded
  /// when the app is open. The snapshot flags it so Home can offer "Always".
  /// With no location permission at all nothing is read; the queue still
  /// uploads and Home says detection is off.
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
    r'28ea6b33881588dbd70dd024173005b158053971';

/// Detection's foreground cycle (v1 `GeofenceLifecycleObserver`, moved out
/// of the widget): run on start, on resume and every 15 s while the app is
/// in front. Hardware location is reconciled less often by the lifecycle.
/// Each run:
///
/// 1. optionally reads a fix and, the first time, seeds the current county
///    from it (else the home county) and registers geofences;
/// 2. when a fix was read, reconciles the current county (an OS-missed
///    crossing becomes a normal exit / enter);
/// 3. captures active candidates, then resolves any past the 2 h dwell;
/// 4. uploads the queue;
/// 5. refreshes the geofence window when a hardware fix was reconciled;
/// 6. offers the newest unseen crossing to the arrival sheet.
///
/// Before any of that it checks permission. Without background location
/// the geofences are removed once but the cycle carries on: a fix is read,
/// the county reconciled and dwell checked, so a visit is still recorded
/// when the app is open. The snapshot flags it so Home can offer "Always".
/// With no location permission at all nothing is read; the queue still
/// uploads and Home says detection is off.
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
