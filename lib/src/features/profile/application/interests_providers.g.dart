// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interests_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The traveller's place interests. Throws when the build has no
/// Supabase (setup only reads it once signed in). Tests override it.

@ProviderFor(interestsRepository)
const interestsRepositoryProvider = InterestsRepositoryProvider._();

/// The traveller's place interests. Throws when the build has no
/// Supabase (setup only reads it once signed in). Tests override it.

final class InterestsRepositoryProvider
    extends
        $FunctionalProvider<
          InterestsRepository,
          InterestsRepository,
          InterestsRepository
        >
    with $Provider<InterestsRepository> {
  /// The traveller's place interests. Throws when the build has no
  /// Supabase (setup only reads it once signed in). Tests override it.
  const InterestsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interestsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interestsRepositoryHash();

  @$internal
  @override
  $ProviderElement<InterestsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InterestsRepository create(Ref ref) {
    return interestsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InterestsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InterestsRepository>(value),
    );
  }
}

String _$interestsRepositoryHash() =>
    r'c06107d450c417642cf0d366fd165d7996e0bcf3';

/// The "Tell us what you like" card's local memory. Tests override it.

@ProviderFor(interestsPromptStore)
const interestsPromptStoreProvider = InterestsPromptStoreProvider._();

/// The "Tell us what you like" card's local memory. Tests override it.

final class InterestsPromptStoreProvider
    extends
        $FunctionalProvider<
          InterestsPromptStore,
          InterestsPromptStore,
          InterestsPromptStore
        >
    with $Provider<InterestsPromptStore> {
  /// The "Tell us what you like" card's local memory. Tests override it.
  const InterestsPromptStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interestsPromptStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interestsPromptStoreHash();

  @$internal
  @override
  $ProviderElement<InterestsPromptStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InterestsPromptStore create(Ref ref) {
    return interestsPromptStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InterestsPromptStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InterestsPromptStore>(value),
    );
  }
}

String _$interestsPromptStoreHash() =>
    r'458cfd0492d08a2d66aa5e79950ff46ab6c32c45';

/// The signed-in user's saved interests (Settings, the editor, and the
/// Home card). Starts from the answer remembered on this phone so it works
/// offline, then quietly refreshes from the server. Never errors: with no
/// answer anywhere it reads as unanswered.

@ProviderFor(MyInterests)
const myInterestsProvider = MyInterestsProvider._();

/// The signed-in user's saved interests (Settings, the editor, and the
/// Home card). Starts from the answer remembered on this phone so it works
/// offline, then quietly refreshes from the server. Never errors: with no
/// answer anywhere it reads as unanswered.
final class MyInterestsProvider
    extends $AsyncNotifierProvider<MyInterests, InterestsAnswer> {
  /// The signed-in user's saved interests (Settings, the editor, and the
  /// Home card). Starts from the answer remembered on this phone so it works
  /// offline, then quietly refreshes from the server. Never errors: with no
  /// answer anywhere it reads as unanswered.
  const MyInterestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myInterestsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myInterestsHash();

  @$internal
  @override
  MyInterests create() => MyInterests();
}

String _$myInterestsHash() => r'46d994477f7dbf02745327553c0db97074724213';

/// The signed-in user's saved interests (Settings, the editor, and the
/// Home card). Starts from the answer remembered on this phone so it works
/// offline, then quietly refreshes from the server. Never errors: with no
/// answer anywhere it reads as unanswered.

abstract class _$MyInterests extends $AsyncNotifier<InterestsAnswer> {
  FutureOr<InterestsAnswer> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<InterestsAnswer>, InterestsAnswer>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<InterestsAnswer>, InterestsAnswer>,
              AsyncValue<InterestsAnswer>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Counts one more app session when first read, and holds the count for
/// the rest of the run, so Home counts a launch once however often it
/// rebuilds.

@ProviderFor(interestsSessionCount)
const interestsSessionCountProvider = InterestsSessionCountProvider._();

/// Counts one more app session when first read, and holds the count for
/// the rest of the run, so Home counts a launch once however often it
/// rebuilds.

final class InterestsSessionCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Counts one more app session when first read, and holds the count for
  /// the rest of the run, so Home counts a launch once however often it
  /// rebuilds.
  const InterestsSessionCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interestsSessionCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interestsSessionCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return interestsSessionCount(ref);
  }
}

String _$interestsSessionCountHash() =>
    r'0e5f123d4bbaaab3d82d9d57ccd64307852c8cf9';

/// Whether Home shows the "Tell us what you like" card: only for someone
/// who has not answered, has not dismissed it, and has opened the app to
/// Home at least [interestsPromptMinSessions] times. Never in the first
/// session.

@ProviderFor(InterestsPrompt)
const interestsPromptProvider = InterestsPromptProvider._();

/// Whether Home shows the "Tell us what you like" card: only for someone
/// who has not answered, has not dismissed it, and has opened the app to
/// Home at least [interestsPromptMinSessions] times. Never in the first
/// session.
final class InterestsPromptProvider
    extends $AsyncNotifierProvider<InterestsPrompt, bool> {
  /// Whether Home shows the "Tell us what you like" card: only for someone
  /// who has not answered, has not dismissed it, and has opened the app to
  /// Home at least [interestsPromptMinSessions] times. Never in the first
  /// session.
  const InterestsPromptProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interestsPromptProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interestsPromptHash();

  @$internal
  @override
  InterestsPrompt create() => InterestsPrompt();
}

String _$interestsPromptHash() => r'e4e2f726ea769e00643417f663b20a52fac821d5';

/// Whether Home shows the "Tell us what you like" card: only for someone
/// who has not answered, has not dismissed it, and has opened the app to
/// Home at least [interestsPromptMinSessions] times. Never in the first
/// session.

abstract class _$InterestsPrompt extends $AsyncNotifier<bool> {
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

/// Which place types count toward each interest, from the backend table so
/// it can change without an app release. Reads as the bundled mapping while
/// loading, offline, or when the table is empty or missing.

@ProviderFor(interestPlaceTypes)
const interestPlaceTypesProvider = InterestPlaceTypesProvider._();

/// Which place types count toward each interest, from the backend table so
/// it can change without an app release. Reads as the bundled mapping while
/// loading, offline, or when the table is empty or missing.

final class InterestPlaceTypesProvider
    extends
        $FunctionalProvider<
          AsyncValue<InterestPlaceTypes>,
          InterestPlaceTypes,
          FutureOr<InterestPlaceTypes>
        >
    with
        $FutureModifier<InterestPlaceTypes>,
        $FutureProvider<InterestPlaceTypes> {
  /// Which place types count toward each interest, from the backend table so
  /// it can change without an app release. Reads as the bundled mapping while
  /// loading, offline, or when the table is empty or missing.
  const InterestPlaceTypesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interestPlaceTypesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interestPlaceTypesHash();

  @$internal
  @override
  $FutureProviderElement<InterestPlaceTypes> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InterestPlaceTypes> create(Ref ref) {
    return interestPlaceTypes(ref);
  }
}

String _$interestPlaceTypesHash() =>
    r'245110a11289c5ffd95e833aa3c879455bd094b5';

/// The interests a traveller can pick from, ordered by the backend's
/// `sort_order`. Starts at once from the list remembered on this phone (or
/// the built-in set), then swaps in the server's active list when it
/// arrives. Never errors and never empty.

@ProviderFor(InterestCatalogue)
const interestCatalogueProvider = InterestCatalogueProvider._();

/// The interests a traveller can pick from, ordered by the backend's
/// `sort_order`. Starts at once from the list remembered on this phone (or
/// the built-in set), then swaps in the server's active list when it
/// arrives. Never errors and never empty.
final class InterestCatalogueProvider
    extends $AsyncNotifierProvider<InterestCatalogue, List<PlaceInterest>> {
  /// The interests a traveller can pick from, ordered by the backend's
  /// `sort_order`. Starts at once from the list remembered on this phone (or
  /// the built-in set), then swaps in the server's active list when it
  /// arrives. Never errors and never empty.
  const InterestCatalogueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interestCatalogueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interestCatalogueHash();

  @$internal
  @override
  InterestCatalogue create() => InterestCatalogue();
}

String _$interestCatalogueHash() => r'adc2c2adcff9b993762fa7a808529c4e61e43f4e';

/// The interests a traveller can pick from, ordered by the backend's
/// `sort_order`. Starts at once from the list remembered on this phone (or
/// the built-in set), then swaps in the server's active list when it
/// arrives. Never errors and never empty.

abstract class _$InterestCatalogue extends $AsyncNotifier<List<PlaceInterest>> {
  FutureOr<List<PlaceInterest>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<PlaceInterest>>, List<PlaceInterest>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PlaceInterest>>, List<PlaceInterest>>,
              AsyncValue<List<PlaceInterest>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Codes of the coastal counties; empty set reads as "not known".

@ProviderFor(coastalCountyCodes)
const coastalCountyCodesProvider = CoastalCountyCodesProvider._();

/// Codes of the coastal counties; empty set reads as "not known".

final class CoastalCountyCodesProvider
    extends
        $FunctionalProvider<AsyncValue<Set<int>>, Set<int>, FutureOr<Set<int>>>
    with $FutureModifier<Set<int>>, $FutureProvider<Set<int>> {
  /// Codes of the coastal counties; empty set reads as "not known".
  const CoastalCountyCodesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coastalCountyCodesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coastalCountyCodesHash();

  @$internal
  @override
  $FutureProviderElement<Set<int>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Set<int>> create(Ref ref) {
    return coastalCountyCodes(ref);
  }
}

String _$coastalCountyCodesHash() =>
    r'92b2bfb77e8517449ba88b83260c96b66ec14680';

/// Type and county rules for matching a place to an interest, from the
/// backend. Reads as the bundled rules until they load.

@ProviderFor(interestMatcher)
const interestMatcherProvider = InterestMatcherProvider._();

/// Type and county rules for matching a place to an interest, from the
/// backend. Reads as the bundled rules until they load.

final class InterestMatcherProvider
    extends
        $FunctionalProvider<InterestMatcher, InterestMatcher, InterestMatcher>
    with $Provider<InterestMatcher> {
  /// Type and county rules for matching a place to an interest, from the
  /// backend. Reads as the bundled rules until they load.
  const InterestMatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'interestMatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$interestMatcherHash();

  @$internal
  @override
  $ProviderElement<InterestMatcher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InterestMatcher create(Ref ref) {
    return interestMatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InterestMatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InterestMatcher>(value),
    );
  }
}

String _$interestMatcherHash() => r'bbb835a9d57e0129f440897b6b2c377998e1f477';
