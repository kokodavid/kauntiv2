// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_key_moments.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kaunti47 places as map pins for the map while recording (same pins as
/// Home). Kept for the session: places change rarely.

@ProviderFor(journeyMapPlaces)
const journeyMapPlacesProvider = JourneyMapPlacesProvider._();

/// Kaunti47 places as map pins for the map while recording (same pins as
/// Home). Kept for the session: places change rarely.

final class JourneyMapPlacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MapPlace>>,
          List<MapPlace>,
          FutureOr<List<MapPlace>>
        >
    with $FutureModifier<List<MapPlace>>, $FutureProvider<List<MapPlace>> {
  /// Kaunti47 places as map pins for the map while recording (same pins as
  /// Home). Kept for the session: places change rarely.
  const JourneyMapPlacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyMapPlacesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyMapPlacesHash();

  @$internal
  @override
  $FutureProviderElement<List<MapPlace>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MapPlace>> create(Ref ref) {
    return journeyMapPlaces(ref);
  }
}

String _$journeyMapPlacesHash() => r'27a21d896568d8f0f668d1106f0c153755141e7d';

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too), photos
/// and the Trip's elevation peak.

@ProviderFor(journeyMoments)
const journeyMomentsProvider = JourneyMomentsFamily._();

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too), photos
/// and the Trip's elevation peak.

final class JourneyMomentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JourneyMoment>>,
          List<JourneyMoment>,
          FutureOr<List<JourneyMoment>>
        >
    with
        $FutureModifier<List<JourneyMoment>>,
        $FutureProvider<List<JourneyMoment>> {
  /// A Journey's key moments, in replay order: recording breaks, long stops,
  /// county crossings (from the bundled boundaries, so offline too), photos
  /// and the Trip's elevation peak.
  const JourneyMomentsProvider._({
    required JourneyMomentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'journeyMomentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journeyMomentsHash();

  @override
  String toString() {
    return r'journeyMomentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<JourneyMoment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<JourneyMoment>> create(Ref ref) {
    final argument = this.argument as String;
    return journeyMoments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JourneyMomentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journeyMomentsHash() => r'e2c3723341ef87d0850f067e31b82c78ab10928f';

/// A Journey's key moments, in replay order: recording breaks, long stops,
/// county crossings (from the bundled boundaries, so offline too), photos
/// and the Trip's elevation peak.

final class JourneyMomentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<JourneyMoment>>, String> {
  const JourneyMomentsFamily._()
    : super(
        retry: null,
        name: r'journeyMomentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A Journey's key moments, in replay order: recording breaks, long stops,
  /// county crossings (from the bundled boundaries, so offline too), photos
  /// and the Trip's elevation peak.

  JourneyMomentsProvider call(String id) =>
      JourneyMomentsProvider._(argument: id, from: this);

  @override
  String toString() => r'journeyMomentsProvider';
}

/// Batched county facts in the cloud, or null when the build has no
/// Supabase.

@ProviderFor(journeyCountyFactsRepository)
const journeyCountyFactsRepositoryProvider =
    JourneyCountyFactsRepositoryProvider._();

/// Batched county facts in the cloud, or null when the build has no
/// Supabase.

final class JourneyCountyFactsRepositoryProvider
    extends
        $FunctionalProvider<
          JourneyCountyFactsRepository?,
          JourneyCountyFactsRepository?,
          JourneyCountyFactsRepository?
        >
    with $Provider<JourneyCountyFactsRepository?> {
  /// Batched county facts in the cloud, or null when the build has no
  /// Supabase.
  const JourneyCountyFactsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeyCountyFactsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyCountyFactsRepositoryHash();

  @$internal
  @override
  $ProviderElement<JourneyCountyFactsRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JourneyCountyFactsRepository? create(Ref ref) {
    return journeyCountyFactsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JourneyCountyFactsRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JourneyCountyFactsRepository?>(
        value,
      ),
    );
  }
}

String _$journeyCountyFactsRepositoryHash() =>
    r'34fc2717690359911a364d9aa314ea55d9e2decc';

/// The "Entered county" card's data for every county this Trip crossed,
/// keyed by county code. Static facts and the visit count come from one
/// batched query; [JourneyCountyMomentFacts.depth] is merged in from the
/// Badges collection already loaded elsewhere, so this never re-derives
/// the depth ladder from scratch.

@ProviderFor(journeyCountyMomentFacts)
const journeyCountyMomentFactsProvider = JourneyCountyMomentFactsFamily._();

/// The "Entered county" card's data for every county this Trip crossed,
/// keyed by county code. Static facts and the visit count come from one
/// batched query; [JourneyCountyMomentFacts.depth] is merged in from the
/// Badges collection already loaded elsewhere, so this never re-derives
/// the depth ladder from scratch.

final class JourneyCountyMomentFactsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, JourneyCountyMomentFacts>>,
          Map<int, JourneyCountyMomentFacts>,
          FutureOr<Map<int, JourneyCountyMomentFacts>>
        >
    with
        $FutureModifier<Map<int, JourneyCountyMomentFacts>>,
        $FutureProvider<Map<int, JourneyCountyMomentFacts>> {
  /// The "Entered county" card's data for every county this Trip crossed,
  /// keyed by county code. Static facts and the visit count come from one
  /// batched query; [JourneyCountyMomentFacts.depth] is merged in from the
  /// Badges collection already loaded elsewhere, so this never re-derives
  /// the depth ladder from scratch.
  const JourneyCountyMomentFactsProvider._({
    required JourneyCountyMomentFactsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'journeyCountyMomentFactsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journeyCountyMomentFactsHash();

  @override
  String toString() {
    return r'journeyCountyMomentFactsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<int, JourneyCountyMomentFacts>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<int, JourneyCountyMomentFacts>> create(Ref ref) {
    final argument = this.argument as String;
    return journeyCountyMomentFacts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JourneyCountyMomentFactsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journeyCountyMomentFactsHash() =>
    r'1b9c02dc884c6211789043b19d913f6c14c7c8ed';

/// The "Entered county" card's data for every county this Trip crossed,
/// keyed by county code. Static facts and the visit count come from one
/// batched query; [JourneyCountyMomentFacts.depth] is merged in from the
/// Badges collection already loaded elsewhere, so this never re-derives
/// the depth ladder from scratch.

final class JourneyCountyMomentFactsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<int, JourneyCountyMomentFacts>>,
          String
        > {
  const JourneyCountyMomentFactsFamily._()
    : super(
        retry: null,
        name: r'journeyCountyMomentFactsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The "Entered county" card's data for every county this Trip crossed,
  /// keyed by county code. Static facts and the visit count come from one
  /// batched query; [JourneyCountyMomentFacts.depth] is merged in from the
  /// Badges collection already loaded elsewhere, so this never re-derives
  /// the depth ladder from scratch.

  JourneyCountyMomentFactsProvider call(String id) =>
      JourneyCountyMomentFactsProvider._(argument: id, from: this);

  @override
  String toString() => r'journeyCountyMomentFactsProvider';
}
