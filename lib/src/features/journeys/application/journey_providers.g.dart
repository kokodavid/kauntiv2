// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(journeyDatabase)
const journeyDatabaseProvider = JourneyDatabaseProvider._();

final class JourneyDatabaseProvider
    extends
        $FunctionalProvider<JourneyDatabase, JourneyDatabase, JourneyDatabase>
    with $Provider<JourneyDatabase> {
  const JourneyDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyDatabaseHash();

  @$internal
  @override
  $ProviderElement<JourneyDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  JourneyDatabase create(Ref ref) {
    return journeyDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyDatabase>(value),
    );
  }
}

String _$journeyDatabaseHash() => r'ef868fec4b4a7377d79dfc4f227f028a05eff6e9';

@ProviderFor(localJourneyRepository)
const localJourneyRepositoryProvider = LocalJourneyRepositoryProvider._();

final class LocalJourneyRepositoryProvider
    extends
        $FunctionalProvider<
          LocalJourneyRepository,
          LocalJourneyRepository,
          LocalJourneyRepository
        >
    with $Provider<LocalJourneyRepository> {
  const LocalJourneyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localJourneyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localJourneyRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocalJourneyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalJourneyRepository create(Ref ref) {
    return localJourneyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalJourneyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalJourneyRepository>(value),
    );
  }
}

String _$localJourneyRepositoryHash() =>
    r'583107c14dc3117ce8c25e67c3cbecd701ae626a';

@ProviderFor(journeyLocationSource)
const journeyLocationSourceProvider = JourneyLocationSourceProvider._();

final class JourneyLocationSourceProvider
    extends
        $FunctionalProvider<
          JourneyLocationSource,
          JourneyLocationSource,
          JourneyLocationSource
        >
    with $Provider<JourneyLocationSource> {
  const JourneyLocationSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyLocationSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyLocationSourceHash();

  @$internal
  @override
  $ProviderElement<JourneyLocationSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JourneyLocationSource create(Ref ref) {
    return journeyLocationSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyLocationSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyLocationSource>(value),
    );
  }
}

String _$journeyLocationSourceHash() =>
    r'1479e1752c4d019b2d6a931a71e32255877d3f39';

@ProviderFor(journeyCapture)
const journeyCaptureProvider = JourneyCaptureProvider._();

final class JourneyCaptureProvider
    extends $FunctionalProvider<JourneyCapture, JourneyCapture, JourneyCapture>
    with $Provider<JourneyCapture> {
  const JourneyCaptureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyCaptureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyCaptureHash();

  @$internal
  @override
  $ProviderElement<JourneyCapture> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  JourneyCapture create(Ref ref) {
    return journeyCapture(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyCapture value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyCapture>(value),
    );
  }
}

String _$journeyCaptureHash() => r'5f424f5547ea43ad3d78fa0045a0ae98c4908109';
