// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_trip_viewer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The viewer-side repository, or null when the build has no Supabase.

@ProviderFor(publicTripViewerRepository)
const publicTripViewerRepositoryProvider =
    PublicTripViewerRepositoryProvider._();

/// The viewer-side repository, or null when the build has no Supabase.

final class PublicTripViewerRepositoryProvider
    extends
        $FunctionalProvider<
          PublicTripViewerRepository?,
          PublicTripViewerRepository?,
          PublicTripViewerRepository?
        >
    with $Provider<PublicTripViewerRepository?> {
  /// The viewer-side repository, or null when the build has no Supabase.
  const PublicTripViewerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publicTripViewerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publicTripViewerRepositoryHash();

  @$internal
  @override
  $ProviderElement<PublicTripViewerRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PublicTripViewerRepository? create(Ref ref) {
    return publicTripViewerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PublicTripViewerRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PublicTripViewerRepository?>(value),
    );
  }
}

String _$publicTripViewerRepositoryHash() =>
    r'8cdebcd1cfe27da7b153c1fd42fe2ed0b555f7bd';

/// How often an open trip re-checks that it is still available. A withdrawn,
/// hidden or blocked trip must not stay on screen.

@ProviderFor(publicTripAccessRecheckInterval)
const publicTripAccessRecheckIntervalProvider =
    PublicTripAccessRecheckIntervalProvider._();

/// How often an open trip re-checks that it is still available. A withdrawn,
/// hidden or blocked trip must not stay on screen.

final class PublicTripAccessRecheckIntervalProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// How often an open trip re-checks that it is still available. A withdrawn,
  /// hidden or blocked trip must not stay on screen.
  const PublicTripAccessRecheckIntervalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publicTripAccessRecheckIntervalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publicTripAccessRecheckIntervalHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return publicTripAccessRecheckInterval(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$publicTripAccessRecheckIntervalHash() =>
    r'91fc4981ecf8dfec60a61a811489d41442a9f4a6';

/// Whether public trips are on for viewers. Signed-out and unknown both read
/// as off, so nothing is offered that might be refused.

@ProviderFor(publicTripReadingEnabled)
const publicTripReadingEnabledProvider = PublicTripReadingEnabledProvider._();

/// Whether public trips are on for viewers. Signed-out and unknown both read
/// as off, so nothing is offered that might be refused.

final class PublicTripReadingEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether public trips are on for viewers. Signed-out and unknown both read
  /// as off, so nothing is offered that might be refused.
  const PublicTripReadingEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publicTripReadingEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publicTripReadingEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return publicTripReadingEnabled(ref);
  }
}

String _$publicTripReadingEnabledHash() =>
    r'dcf75a45920b3118c75c8ce30bb5d5b1a6e64869';

/// Home's row: public trips near [countyCode]. Any failure is an empty row
/// rather than an error, because the row is a bonus on Home.

@ProviderFor(publicTripsForYou)
const publicTripsForYouProvider = PublicTripsForYouFamily._();

/// Home's row: public trips near [countyCode]. Any failure is an empty row
/// rather than an error, because the row is a bonus on Home.

final class PublicTripsForYouProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PublicTripView>>,
          List<PublicTripView>,
          FutureOr<List<PublicTripView>>
        >
    with
        $FutureModifier<List<PublicTripView>>,
        $FutureProvider<List<PublicTripView>> {
  /// Home's row: public trips near [countyCode]. Any failure is an empty row
  /// rather than an error, because the row is a bonus on Home.
  const PublicTripsForYouProvider._({
    required PublicTripsForYouFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'publicTripsForYouProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$publicTripsForYouHash();

  @override
  String toString() {
    return r'publicTripsForYouProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PublicTripView>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PublicTripView>> create(Ref ref) {
    final argument = this.argument as int;
    return publicTripsForYou(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicTripsForYouProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$publicTripsForYouHash() => r'079b9216213f5e761252e1dd94258882f607d3bb';

/// Home's row: public trips near [countyCode]. Any failure is an empty row
/// rather than an error, because the row is a bonus on Home.

final class PublicTripsForYouFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PublicTripView>>, int> {
  const PublicTripsForYouFamily._()
    : super(
        retry: null,
        name: r'publicTripsForYouProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Home's row: public trips near [countyCode]. Any failure is an empty row
  /// rather than an error, because the row is a bonus on Home.

  PublicTripsForYouProvider call(int countyCode) =>
      PublicTripsForYouProvider._(argument: countyCode, from: this);

  @override
  String toString() => r'publicTripsForYouProvider';
}

/// One live trip, or null when it is not available to this viewer.

@ProviderFor(publicTrip)
const publicTripProvider = PublicTripFamily._();

/// One live trip, or null when it is not available to this viewer.

final class PublicTripProvider
    extends
        $FunctionalProvider<
          AsyncValue<PublicTripView?>,
          PublicTripView?,
          FutureOr<PublicTripView?>
        >
    with $FutureModifier<PublicTripView?>, $FutureProvider<PublicTripView?> {
  /// One live trip, or null when it is not available to this viewer.
  const PublicTripProvider._({
    required PublicTripFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'publicTripProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$publicTripHash();

  @override
  String toString() {
    return r'publicTripProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PublicTripView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PublicTripView?> create(Ref ref) {
    final argument = this.argument as String;
    return publicTrip(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicTripProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$publicTripHash() => r'9d945001ee75fb6b3e6c81fe048155b41fa7aeca';

/// One live trip, or null when it is not available to this viewer.

final class PublicTripFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PublicTripView?>, String> {
  const PublicTripFamily._()
    : super(
        retry: null,
        name: r'publicTripProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One live trip, or null when it is not available to this viewer.

  PublicTripProvider call(String publicationId) =>
      PublicTripProvider._(argument: publicationId, from: this);

  @override
  String toString() => r'publicTripProvider';
}

/// Photo links for a trip revision, keyed by photo ID. Kept per revision so
/// the periodic access check does not sign the photos again each time.

@ProviderFor(publicTripPhotoUrls)
const publicTripPhotoUrlsProvider = PublicTripPhotoUrlsFamily._();

/// Photo links for a trip revision, keyed by photo ID. Kept per revision so
/// the periodic access check does not sign the photos again each time.

final class PublicTripPhotoUrlsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $FutureProvider<Map<String, String>> {
  /// Photo links for a trip revision, keyed by photo ID. Kept per revision so
  /// the periodic access check does not sign the photos again each time.
  const PublicTripPhotoUrlsProvider._({
    required PublicTripPhotoUrlsFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'publicTripPhotoUrlsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$publicTripPhotoUrlsHash();

  @override
  String toString() {
    return r'publicTripPhotoUrlsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String>> create(Ref ref) {
    final argument = this.argument as (String, int);
    return publicTripPhotoUrls(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicTripPhotoUrlsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$publicTripPhotoUrlsHash() =>
    r'4dc370f7bac92bcb1d8032066abfedc055d2c516';

/// Photo links for a trip revision, keyed by photo ID. Kept per revision so
/// the periodic access check does not sign the photos again each time.

final class PublicTripPhotoUrlsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<String, String>>,
          (String, int)
        > {
  const PublicTripPhotoUrlsFamily._()
    : super(
        retry: null,
        name: r'publicTripPhotoUrlsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Photo links for a trip revision, keyed by photo ID. Kept per revision so
  /// the periodic access check does not sign the photos again each time.

  PublicTripPhotoUrlsProvider call(String publicationId, int revision) =>
      PublicTripPhotoUrlsProvider._(
        argument: (publicationId, revision),
        from: this,
      );

  @override
  String toString() => r'publicTripPhotoUrlsProvider';
}

/// Reports and blocks. Stateless: each call either completes or throws a
/// [PublicTripFailure] with a message fit to show.

@ProviderFor(PublicTripViewerActions)
const publicTripViewerActionsProvider = PublicTripViewerActionsProvider._();

/// Reports and blocks. Stateless: each call either completes or throws a
/// [PublicTripFailure] with a message fit to show.
final class PublicTripViewerActionsProvider
    extends $NotifierProvider<PublicTripViewerActions, void> {
  /// Reports and blocks. Stateless: each call either completes or throws a
  /// [PublicTripFailure] with a message fit to show.
  const PublicTripViewerActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publicTripViewerActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publicTripViewerActionsHash();

  @$internal
  @override
  PublicTripViewerActions create() => PublicTripViewerActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$publicTripViewerActionsHash() =>
    r'c0661e55a8c05ed86e5932bf145702697dd6a902';

/// Reports and blocks. Stateless: each call either completes or throws a
/// [PublicTripFailure] with a message fit to show.

abstract class _$PublicTripViewerActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
