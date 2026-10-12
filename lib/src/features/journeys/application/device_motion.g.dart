// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_motion.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceMotionSource)
const deviceMotionSourceProvider = DeviceMotionSourceProvider._();

final class DeviceMotionSourceProvider
    extends
        $FunctionalProvider<
          DeviceMotionSource,
          DeviceMotionSource,
          DeviceMotionSource
        >
    with $Provider<DeviceMotionSource> {
  const DeviceMotionSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceMotionSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceMotionSourceHash();

  @$internal
  @override
  $ProviderElement<DeviceMotionSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceMotionSource create(Ref ref) {
    return deviceMotionSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceMotionSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceMotionSource>(value),
    );
  }
}

String _$deviceMotionSourceHash() =>
    r'4ee44e0c817dab1a07dc7418aebd82054fbe1e4a';

/// A Trip is recording (not paused). Its own provider so listeners rebuild
/// only when this flips, not on every recorder change.

@ProviderFor(isJourneyRecording)
const isJourneyRecordingProvider = IsJourneyRecordingProvider._();

/// A Trip is recording (not paused). Its own provider so listeners rebuild
/// only when this flips, not on every recorder change.

final class IsJourneyRecordingProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// A Trip is recording (not paused). Its own provider so listeners rebuild
  /// only when this flips, not on every recorder change.
  const IsJourneyRecordingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isJourneyRecordingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isJourneyRecordingHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isJourneyRecording(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isJourneyRecordingHash() =>
    r'982080ef1d42810b5a0382edf9345316f615d1fc';

/// Whether the phone is moving, for Home. Watch it only while Home is on
/// screen: it holds a location stream open and closes it when nobody
/// listens. While a Trip records, the recorder owns location and this stays
/// [MotionState.unknown].

@ProviderFor(deviceMotion)
const deviceMotionProvider = DeviceMotionProvider._();

/// Whether the phone is moving, for Home. Watch it only while Home is on
/// screen: it holds a location stream open and closes it when nobody
/// listens. While a Trip records, the recorder owns location and this stays
/// [MotionState.unknown].

final class DeviceMotionProvider
    extends
        $FunctionalProvider<
          AsyncValue<MotionState>,
          MotionState,
          Stream<MotionState>
        >
    with $FutureModifier<MotionState>, $StreamProvider<MotionState> {
  /// Whether the phone is moving, for Home. Watch it only while Home is on
  /// screen: it holds a location stream open and closes it when nobody
  /// listens. While a Trip records, the recorder owns location and this stays
  /// [MotionState.unknown].
  const DeviceMotionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceMotionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceMotionHash();

  @$internal
  @override
  $StreamProviderElement<MotionState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MotionState> create(Ref ref) {
    return deviceMotion(ref);
  }
}

String _$deviceMotionHash() => r'9144eac18c8b535c8353bd6c220c44acea5831a8';
