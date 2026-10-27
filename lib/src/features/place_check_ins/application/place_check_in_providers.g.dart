// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_check_in_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null when the build has no Supabase. Tests override it.

@ProviderFor(placeCheckInRepository)
const placeCheckInRepositoryProvider = PlaceCheckInRepositoryProvider._();

/// Null when the build has no Supabase. Tests override it.

final class PlaceCheckInRepositoryProvider
    extends
        $FunctionalProvider<
          PlaceCheckInRepository?,
          PlaceCheckInRepository?,
          PlaceCheckInRepository?
        >
    with $Provider<PlaceCheckInRepository?> {
  /// Null when the build has no Supabase. Tests override it.
  const PlaceCheckInRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeCheckInRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeCheckInRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaceCheckInRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaceCheckInRepository? create(Ref ref) {
    return placeCheckInRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceCheckInRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceCheckInRepository?>(value),
    );
  }
}

String _$placeCheckInRepositoryHash() =>
    r'de9dd10ddb10cb4871b6d342a93b89a8b6ef1c76';

/// Whether the card shows, and whether this place is already done today.
/// A failed read counts as off, so the card never appears when it can't be
/// trusted.

@ProviderFor(placeCheckInStatus)
const placeCheckInStatusProvider = PlaceCheckInStatusFamily._();

/// Whether the card shows, and whether this place is already done today.
/// A failed read counts as off, so the card never appears when it can't be
/// trusted.

final class PlaceCheckInStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlaceCheckInStatus>,
          PlaceCheckInStatus,
          FutureOr<PlaceCheckInStatus>
        >
    with
        $FutureModifier<PlaceCheckInStatus>,
        $FutureProvider<PlaceCheckInStatus> {
  /// Whether the card shows, and whether this place is already done today.
  /// A failed read counts as off, so the card never appears when it can't be
  /// trusted.
  const PlaceCheckInStatusProvider._({
    required PlaceCheckInStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'placeCheckInStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$placeCheckInStatusHash();

  @override
  String toString() {
    return r'placeCheckInStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlaceCheckInStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlaceCheckInStatus> create(Ref ref) {
    final argument = this.argument as String;
    return placeCheckInStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaceCheckInStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$placeCheckInStatusHash() =>
    r'312f9a38bea97ed852b327112bc56a5b52c49b04';

/// Whether the card shows, and whether this place is already done today.
/// A failed read counts as off, so the card never appears when it can't be
/// trusted.

final class PlaceCheckInStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlaceCheckInStatus>, String> {
  const PlaceCheckInStatusFamily._()
    : super(
        retry: null,
        name: r'placeCheckInStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the card shows, and whether this place is already done today.
  /// A failed read counts as off, so the card never appears when it can't be
  /// trusted.

  PlaceCheckInStatusProvider call(String placeId) =>
      PlaceCheckInStatusProvider._(argument: placeId, from: this);

  @override
  String toString() => r'placeCheckInStatusProvider';
}

/// Sends the check-in and refreshes what depends on it. State is the last
/// answer (null before the first tap); loading while the position is read.

@ProviderFor(PlaceCheckInController)
const placeCheckInControllerProvider = PlaceCheckInControllerFamily._();

/// Sends the check-in and refreshes what depends on it. State is the last
/// answer (null before the first tap); loading while the position is read.
final class PlaceCheckInControllerProvider
    extends $AsyncNotifierProvider<PlaceCheckInController, CheckInOutcome?> {
  /// Sends the check-in and refreshes what depends on it. State is the last
  /// answer (null before the first tap); loading while the position is read.
  const PlaceCheckInControllerProvider._({
    required PlaceCheckInControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'placeCheckInControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$placeCheckInControllerHash();

  @override
  String toString() {
    return r'placeCheckInControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlaceCheckInController create() => PlaceCheckInController();

  @override
  bool operator ==(Object other) {
    return other is PlaceCheckInControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$placeCheckInControllerHash() =>
    r'5232c3a1add24434b945b267ca4ba84bf1ff0d39';

/// Sends the check-in and refreshes what depends on it. State is the last
/// answer (null before the first tap); loading while the position is read.

final class PlaceCheckInControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PlaceCheckInController,
          AsyncValue<CheckInOutcome?>,
          CheckInOutcome?,
          FutureOr<CheckInOutcome?>,
          String
        > {
  const PlaceCheckInControllerFamily._()
    : super(
        retry: null,
        name: r'placeCheckInControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Sends the check-in and refreshes what depends on it. State is the last
  /// answer (null before the first tap); loading while the position is read.

  PlaceCheckInControllerProvider call(String placeId) =>
      PlaceCheckInControllerProvider._(argument: placeId, from: this);

  @override
  String toString() => r'placeCheckInControllerProvider';
}

/// Sends the check-in and refreshes what depends on it. State is the last
/// answer (null before the first tap); loading while the position is read.

abstract class _$PlaceCheckInController
    extends $AsyncNotifier<CheckInOutcome?> {
  late final _$args = ref.$arg as String;
  String get placeId => _$args;

  FutureOr<CheckInOutcome?> build(String placeId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<CheckInOutcome?>, CheckInOutcome?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CheckInOutcome?>, CheckInOutcome?>,
              AsyncValue<CheckInOutcome?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
