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

/// Which Explore tab is showing. Kept alive so another tab (Home's "All N
/// left") can pick it before Explore is first built.

@ProviderFor(ExploreTabSelection)
const exploreTabSelectionProvider = ExploreTabSelectionProvider._();

/// Which Explore tab is showing. Kept alive so another tab (Home's "All N
/// left") can pick it before Explore is first built.
final class ExploreTabSelectionProvider
    extends $NotifierProvider<ExploreTabSelection, ExploreTab> {
  /// Which Explore tab is showing. Kept alive so another tab (Home's "All N
  /// left") can pick it before Explore is first built.
  const ExploreTabSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreTabSelectionProvider',
        isAutoDispose: false,
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
    r'6e8a230ba23e2fd0bd1ac340f967c4b03982ddf0';

/// Which Explore tab is showing. Kept alive so another tab (Home's "All N
/// left") can pick it before Explore is first built.

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

/// Place save changes made from Explore since the board loaded, by place
/// id, so rows rebuilt after scrolling show the latest state.

@ProviderFor(ExploreSavedPlaces)
const exploreSavedPlacesProvider = ExploreSavedPlacesProvider._();

/// Place save changes made from Explore since the board loaded, by place
/// id, so rows rebuilt after scrolling show the latest state.
final class ExploreSavedPlacesProvider
    extends $NotifierProvider<ExploreSavedPlaces, Map<String, bool>> {
  /// Place save changes made from Explore since the board loaded, by place
  /// id, so rows rebuilt after scrolling show the latest state.
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
    r'c06543a5e4def6643de72abc7ca8437969141dad';

/// Place save changes made from Explore since the board loaded, by place
/// id, so rows rebuilt after scrolling show the latest state.

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

/// County-only saves from UNCLAIMED's Save button, by county code.

@ProviderFor(ExploreSavedCounties)
const exploreSavedCountiesProvider = ExploreSavedCountiesProvider._();

/// County-only saves from UNCLAIMED's Save button, by county code.
final class ExploreSavedCountiesProvider
    extends $NotifierProvider<ExploreSavedCounties, Map<int, bool>> {
  /// County-only saves from UNCLAIMED's Save button, by county code.
  const ExploreSavedCountiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreSavedCountiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreSavedCountiesHash();

  @$internal
  @override
  ExploreSavedCounties create() => ExploreSavedCounties();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, bool>>(value),
    );
  }
}

String _$exploreSavedCountiesHash() =>
    r'b700a45665427a0bd980d38e7e0714d4d5f5bd86';

/// County-only saves from UNCLAIMED's Save button, by county code.

abstract class _$ExploreSavedCounties extends $Notifier<Map<int, bool>> {
  Map<int, bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Map<int, bool>, Map<int, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<int, bool>, Map<int, bool>>,
              Map<int, bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Hand-ticked SAVED places since the board loaded, by place id.

@ProviderFor(ExploreTickedPlaces)
const exploreTickedPlacesProvider = ExploreTickedPlacesProvider._();

/// Hand-ticked SAVED places since the board loaded, by place id.
final class ExploreTickedPlacesProvider
    extends $NotifierProvider<ExploreTickedPlaces, Map<String, bool>> {
  /// Hand-ticked SAVED places since the board loaded, by place id.
  const ExploreTickedPlacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreTickedPlacesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreTickedPlacesHash();

  @$internal
  @override
  ExploreTickedPlaces create() => ExploreTickedPlaces();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$exploreTickedPlacesHash() =>
    r'2f4f39f98dab233362ad92b91132349a7f06c33d';

/// Hand-ticked SAVED places since the board loaded, by place id.

abstract class _$ExploreTickedPlaces extends $Notifier<Map<String, bool>> {
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
