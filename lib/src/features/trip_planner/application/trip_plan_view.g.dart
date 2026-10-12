// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_plan_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The stops key the route is planned for. It follows the picked stops and
/// their order once they settle, so a run of taps asks Mapbox once.

@ProviderFor(TripPlanKey)
const tripPlanKeyProvider = TripPlanKeyFamily._();

/// The stops key the route is planned for. It follows the picked stops and
/// their order once they settle, so a run of taps asks Mapbox once.
final class TripPlanKeyProvider extends $NotifierProvider<TripPlanKey, String> {
  /// The stops key the route is planned for. It follows the picked stops and
  /// their order once they settle, so a run of taps asks Mapbox once.
  const TripPlanKeyProvider._({
    required TripPlanKeyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripPlanKeyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripPlanKeyHash();

  @override
  String toString() {
    return r'tripPlanKeyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TripPlanKey create() => TripPlanKey();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripPlanKeyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripPlanKeyHash() => r'afffff7c9c27e3231f2eb8e3d215d3d63bcfb515';

/// The stops key the route is planned for. It follows the picked stops and
/// their order once they settle, so a run of taps asks Mapbox once.

final class TripPlanKeyFamily extends $Family
    with $ClassFamilyOverride<TripPlanKey, String, String, String, String> {
  const TripPlanKeyFamily._()
    : super(
        retry: null,
        name: r'tripPlanKeyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The stops key the route is planned for. It follows the picked stops and
  /// their order once they settle, so a run of taps asks Mapbox once.

  TripPlanKeyProvider call(String placeId) =>
      TripPlanKeyProvider._(argument: placeId, from: this);

  @override
  String toString() => r'tripPlanKeyProvider';
}

/// The stops key the route is planned for. It follows the picked stops and
/// their order once they settle, so a run of taps asks Mapbox once.

abstract class _$TripPlanKey extends $Notifier<String> {
  late final _$args = ref.$arg as String;
  String get placeId => _$args;

  String build(String placeId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// The plan as the Plan trip tab, the full-screen map and the Start bar
/// show it. Keeps the last route on screen while the next one is planned.

@ProviderFor(TripPlanView)
const tripPlanViewProvider = TripPlanViewFamily._();

/// The plan as the Plan trip tab, the full-screen map and the Start bar
/// show it. Keeps the last route on screen while the next one is planned.
final class TripPlanViewProvider
    extends $NotifierProvider<TripPlanView, TripPlanSnapshot> {
  /// The plan as the Plan trip tab, the full-screen map and the Start bar
  /// show it. Keeps the last route on screen while the next one is planned.
  const TripPlanViewProvider._({
    required TripPlanViewFamily super.from,
    required (String, double, double) super.argument,
  }) : super(
         retry: null,
         name: r'tripPlanViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripPlanViewHash();

  @override
  String toString() {
    return r'tripPlanViewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TripPlanView create() => TripPlanView();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripPlanSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripPlanSnapshot>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripPlanViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripPlanViewHash() => r'f63be72fa8656729b1b19b6dadcd131c1e136cbb';

/// The plan as the Plan trip tab, the full-screen map and the Start bar
/// show it. Keeps the last route on screen while the next one is planned.

final class TripPlanViewFamily extends $Family
    with
        $ClassFamilyOverride<
          TripPlanView,
          TripPlanSnapshot,
          TripPlanSnapshot,
          TripPlanSnapshot,
          (String, double, double)
        > {
  const TripPlanViewFamily._()
    : super(
        retry: null,
        name: r'tripPlanViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The plan as the Plan trip tab, the full-screen map and the Start bar
  /// show it. Keeps the last route on screen while the next one is planned.

  TripPlanViewProvider call(String placeId, double lat, double lng) =>
      TripPlanViewProvider._(argument: (placeId, lat, lng), from: this);

  @override
  String toString() => r'tripPlanViewProvider';
}

/// The plan as the Plan trip tab, the full-screen map and the Start bar
/// show it. Keeps the last route on screen while the next one is planned.

abstract class _$TripPlanView extends $Notifier<TripPlanSnapshot> {
  late final _$args = ref.$arg as (String, double, double);
  String get placeId => _$args.$1;
  double get lat => _$args.$2;
  double get lng => _$args.$3;

  TripPlanSnapshot build(String placeId, double lat, double lng);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args.$1, _$args.$2, _$args.$3);
    final ref = this.ref as $Ref<TripPlanSnapshot, TripPlanSnapshot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TripPlanSnapshot, TripPlanSnapshot>,
              TripPlanSnapshot,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
