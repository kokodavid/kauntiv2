// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'county_tracking.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(countyTrackingPreference)
const countyTrackingPreferenceProvider = CountyTrackingPreferenceProvider._();

final class CountyTrackingPreferenceProvider
    extends
        $FunctionalProvider<
          CountyTrackingPreference,
          CountyTrackingPreference,
          CountyTrackingPreference
        >
    with $Provider<CountyTrackingPreference> {
  const CountyTrackingPreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countyTrackingPreferenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countyTrackingPreferenceHash();

  @$internal
  @override
  $ProviderElement<CountyTrackingPreference> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CountyTrackingPreference create(Ref ref) {
    return countyTrackingPreference(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CountyTrackingPreference value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CountyTrackingPreference>(value),
    );
  }
}

String _$countyTrackingPreferenceHash() =>
    r'e579d32a9f5297761a65471ef97e37387b71ff55';

@ProviderFor(countyTrackingSource)
const countyTrackingSourceProvider = CountyTrackingSourceProvider._();

final class CountyTrackingSourceProvider
    extends
        $FunctionalProvider<
          CountyTrackingSource,
          CountyTrackingSource,
          CountyTrackingSource
        >
    with $Provider<CountyTrackingSource> {
  const CountyTrackingSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countyTrackingSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countyTrackingSourceHash();

  @$internal
  @override
  $ProviderElement<CountyTrackingSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CountyTrackingSource create(Ref ref) {
    return countyTrackingSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CountyTrackingSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CountyTrackingSource>(value),
    );
  }
}

String _$countyTrackingSourceHash() =>
    r'dc7d2d4d0464f17855a620ea69812d77e9670e90';

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

@ProviderFor(CountyTracking)
const countyTrackingProvider = CountyTrackingProvider._();

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
final class CountyTrackingProvider
    extends $AsyncNotifierProvider<CountyTracking, bool> {
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
  const CountyTrackingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countyTrackingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countyTrackingHash();

  @$internal
  @override
  CountyTracking create() => CountyTracking();
}

String _$countyTrackingHash() => r'bcde5c360a5b5203d2d1040305e9106709696c7b';

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

abstract class _$CountyTracking extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
