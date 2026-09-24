// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Visit timings: [VisitTimings.current] (dev timings in debug builds,
/// production in release), the same rule the background isolate uses.
/// Tests override it.

@ProviderFor(visitTimings)
const visitTimingsProvider = VisitTimingsProvider._();

/// Visit timings: [VisitTimings.current] (dev timings in debug builds,
/// production in release), the same rule the background isolate uses.
/// Tests override it.

final class VisitTimingsProvider
    extends $FunctionalProvider<VisitTimings, VisitTimings, VisitTimings>
    with $Provider<VisitTimings> {
  /// Visit timings: [VisitTimings.current] (dev timings in debug builds,
  /// production in release), the same rule the background isolate uses.
  /// Tests override it.
  const VisitTimingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitTimingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitTimingsHash();

  @$internal
  @override
  $ProviderElement<VisitTimings> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VisitTimings create(Ref ref) {
    return visitTimings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VisitTimings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VisitTimings>(value),
    );
  }
}

String _$visitTimingsHash() => r'41e3fd781863a0b8595251bc6cc82a5a047fb357';

/// The on-device detection database (`detection_queue`), open for the
/// life of the app.

@ProviderFor(detectionDatabase)
const detectionDatabaseProvider = DetectionDatabaseProvider._();

/// The on-device detection database (`detection_queue`), open for the
/// life of the app.

final class DetectionDatabaseProvider
    extends
        $FunctionalProvider<
          DetectionDatabase,
          DetectionDatabase,
          DetectionDatabase
        >
    with $Provider<DetectionDatabase> {
  /// The on-device detection database (`detection_queue`), open for the
  /// life of the app.
  const DetectionDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detectionDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detectionDatabaseHash();

  @$internal
  @override
  $ProviderElement<DetectionDatabase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DetectionDatabase create(Ref ref) {
    return detectionDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DetectionDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DetectionDatabase>(value),
    );
  }
}

String _$detectionDatabaseHash() => r'a45616b9dfacb29f00d3b52c26a2da341042b680';

/// Detection state bound to the signed-in user (null when signed out, so
/// nothing is recorded or attributed without an owner).

@ProviderFor(detectionRepository)
const detectionRepositoryProvider = DetectionRepositoryProvider._();

/// Detection state bound to the signed-in user (null when signed out, so
/// nothing is recorded or attributed without an owner).

final class DetectionRepositoryProvider
    extends
        $FunctionalProvider<
          DetectionRepository,
          DetectionRepository,
          DetectionRepository
        >
    with $Provider<DetectionRepository> {
  /// Detection state bound to the signed-in user (null when signed out, so
  /// nothing is recorded or attributed without an owner).
  const DetectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detectionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<DetectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DetectionRepository create(Ref ref) {
    return detectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DetectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DetectionRepository>(value),
    );
  }
}

String _$detectionRepositoryHash() =>
    r'1353798e4753a51737c2c882b14de6c3fdcdebaa';

/// OS geofence registration (the rolling county window).

@ProviderFor(geofenceService)
const geofenceServiceProvider = GeofenceServiceProvider._();

/// OS geofence registration (the rolling county window).

final class GeofenceServiceProvider
    extends
        $FunctionalProvider<GeofenceService, GeofenceService, GeofenceService>
    with $Provider<GeofenceService> {
  /// OS geofence registration (the rolling county window).
  const GeofenceServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geofenceServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geofenceServiceHash();

  @$internal
  @override
  $ProviderElement<GeofenceService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GeofenceService create(Ref ref) {
    return geofenceService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeofenceService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeofenceService>(value),
    );
  }
}

String _$geofenceServiceHash() => r'5bb4343cf6bdd0603b1ffe323bb207842a50524a';

/// Background location permission for detection. Tests override it.

@ProviderFor(detectionPermission)
const detectionPermissionProvider = DetectionPermissionProvider._();

/// Background location permission for detection. Tests override it.

final class DetectionPermissionProvider
    extends
        $FunctionalProvider<
          DetectionPermission,
          DetectionPermission,
          DetectionPermission
        >
    with $Provider<DetectionPermission> {
  /// Background location permission for detection. Tests override it.
  const DetectionPermissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detectionPermissionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detectionPermissionHash();

  @$internal
  @override
  $ProviderElement<DetectionPermission> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DetectionPermission create(Ref ref) {
    return detectionPermission(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DetectionPermission value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DetectionPermission>(value),
    );
  }
}

String _$detectionPermissionHash() =>
    r'4f54fa63f680092aeae8f79cfe987fd845ad9241';
