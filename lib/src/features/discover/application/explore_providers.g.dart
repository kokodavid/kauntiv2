// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exploreRepository)
const exploreRepositoryProvider = ExploreRepositoryProvider._();

final class ExploreRepositoryProvider
    extends
        $FunctionalProvider<
          ExploreRepository,
          ExploreRepository,
          ExploreRepository
        >
    with $Provider<ExploreRepository> {
  const ExploreRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExploreRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExploreRepository create(Ref ref) {
    return exploreRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExploreRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExploreRepository>(value),
    );
  }
}

String _$exploreRepositoryHash() => r'd2f22aa5c09ce279da4dbd7ee14ffca44b615822';

@ProviderFor(discoverDetailRepository)
const discoverDetailRepositoryProvider = DiscoverDetailRepositoryProvider._();

final class DiscoverDetailRepositoryProvider
    extends
        $FunctionalProvider<
          DiscoverDetailRepository,
          DiscoverDetailRepository,
          DiscoverDetailRepository
        >
    with $Provider<DiscoverDetailRepository> {
  const DiscoverDetailRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoverDetailRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoverDetailRepositoryHash();

  @$internal
  @override
  $ProviderElement<DiscoverDetailRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiscoverDetailRepository create(Ref ref) {
    return discoverDetailRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiscoverDetailRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiscoverDetailRepository>(value),
    );
  }
}

String _$discoverDetailRepositoryHash() =>
    r'e67fd31d6af8a6081690f1a09b933fceeb24be7d';

/// Explore's board. Kept alive by the tab shell, which keeps Explore
/// mounted once visited; invalidate it to reload.

@ProviderFor(exploreBoard)
const exploreBoardProvider = ExploreBoardProvider._();

/// Explore's board. Kept alive by the tab shell, which keeps Explore
/// mounted once visited; invalidate it to reload.

final class ExploreBoardProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExploreBoard>,
          ExploreBoard,
          FutureOr<ExploreBoard>
        >
    with $FutureModifier<ExploreBoard>, $FutureProvider<ExploreBoard> {
  /// Explore's board. Kept alive by the tab shell, which keeps Explore
  /// mounted once visited; invalidate it to reload.
  const ExploreBoardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreBoardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreBoardHash();

  @$internal
  @override
  $FutureProviderElement<ExploreBoard> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExploreBoard> create(Ref ref) {
    return exploreBoard(ref);
  }
}

String _$exploreBoardHash() => r'e742248429224a11afa45120fd16a6e93b49fb0d';

/// Which Explore tab is showing.

@ProviderFor(ExploreTabSelection)
const exploreTabSelectionProvider = ExploreTabSelectionProvider._();

/// Which Explore tab is showing.
final class ExploreTabSelectionProvider
    extends $NotifierProvider<ExploreTabSelection, ExploreTab> {
  /// Which Explore tab is showing.
  const ExploreTabSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreTabSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreTabSelectionHash();

  @$internal
  @override
  ExploreTabSelection create() => ExploreTabSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExploreTab value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExploreTab>(value),
    );
  }
}

String _$exploreTabSelectionHash() =>
    r'6b7fcb051505d2194b916600633df837228be65a';

/// Which Explore tab is showing.

abstract class _$ExploreTabSelection extends $Notifier<ExploreTab> {
  ExploreTab build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ExploreTab, ExploreTab>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExploreTab, ExploreTab>,
              ExploreTab,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// The Explore search text, applied across tabs.

@ProviderFor(ExploreSearchQuery)
const exploreSearchQueryProvider = ExploreSearchQueryProvider._();

/// The Explore search text, applied across tabs.
final class ExploreSearchQueryProvider
    extends $NotifierProvider<ExploreSearchQuery, String> {
  /// The Explore search text, applied across tabs.
  const ExploreSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreSearchQueryHash();

  @$internal
  @override
  ExploreSearchQuery create() => ExploreSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$exploreSearchQueryHash() =>
    r'710279d17c0bcb58ded500a0618f44afe0e1cf7b';

/// The Explore search text, applied across tabs.

abstract class _$ExploreSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
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

/// Save / un-save changes made from Explore since the board loaded, by
/// place id, so rows rebuilt after scrolling show the latest state
/// without reloading the board.

@ProviderFor(ExploreSavedPlaces)
const exploreSavedPlacesProvider = ExploreSavedPlacesProvider._();

/// Save / un-save changes made from Explore since the board loaded, by
/// place id, so rows rebuilt after scrolling show the latest state
/// without reloading the board.
final class ExploreSavedPlacesProvider
    extends $NotifierProvider<ExploreSavedPlaces, Map<String, bool>> {
  /// Save / un-save changes made from Explore since the board loaded, by
  /// place id, so rows rebuilt after scrolling show the latest state
  /// without reloading the board.
  const ExploreSavedPlacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreSavedPlacesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreSavedPlacesHash();

  @$internal
  @override
  ExploreSavedPlaces create() => ExploreSavedPlaces();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$exploreSavedPlacesHash() =>
    r'536d470114016db8e6e41e1b258293d6baea22af';

/// Save / un-save changes made from Explore since the board loaded, by
/// place id, so rows rebuilt after scrolling show the latest state
/// without reloading the board.

abstract class _$ExploreSavedPlaces extends $Notifier<Map<String, bool>> {
  Map<String, bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Map<String, bool>, Map<String, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, bool>, Map<String, bool>>,
              Map<String, bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
