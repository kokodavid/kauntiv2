// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_place_search.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The start-point search. Null in a build without a Mapbox token.

@ProviderFor(planPlaceSearchClient)
const planPlaceSearchClientProvider = PlanPlaceSearchClientProvider._();

/// The start-point search. Null in a build without a Mapbox token.

final class PlanPlaceSearchClientProvider
    extends
        $FunctionalProvider<
          PlanPlaceSearchClient?,
          PlanPlaceSearchClient?,
          PlanPlaceSearchClient?
        >
    with $Provider<PlanPlaceSearchClient?> {
  /// The start-point search. Null in a build without a Mapbox token.
  const PlanPlaceSearchClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planPlaceSearchClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planPlaceSearchClientHash();

  @$internal
  @override
  $ProviderElement<PlanPlaceSearchClient?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlanPlaceSearchClient? create(Ref ref) {
    return planPlaceSearchClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanPlaceSearchClient? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanPlaceSearchClient?>(value),
    );
  }
}

String _$planPlaceSearchClientHash() =>
    r'f85139afeec55cda1fe11ec12db1ab4bd3ae9cef';

/// Suggestions for what has been typed. Waits a moment first so a burst of
/// typing asks once, and favours spots near the user. A failure is thrown,
/// so the page can say so and offer Retry.

@ProviderFor(planPlaceSuggestions)
const planPlaceSuggestionsProvider = PlanPlaceSuggestionsFamily._();

/// Suggestions for what has been typed. Waits a moment first so a burst of
/// typing asks once, and favours spots near the user. A failure is thrown,
/// so the page can say so and offer Retry.

final class PlanPlaceSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanPlaceSuggestion>>,
          List<PlanPlaceSuggestion>,
          FutureOr<List<PlanPlaceSuggestion>>
        >
    with
        $FutureModifier<List<PlanPlaceSuggestion>>,
        $FutureProvider<List<PlanPlaceSuggestion>> {
  /// Suggestions for what has been typed. Waits a moment first so a burst of
  /// typing asks once, and favours spots near the user. A failure is thrown,
  /// so the page can say so and offer Retry.
  const PlanPlaceSuggestionsProvider._({
    required PlanPlaceSuggestionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planPlaceSuggestionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planPlaceSuggestionsHash();

  @override
  String toString() {
    return r'planPlaceSuggestionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlanPlaceSuggestion>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlanPlaceSuggestion>> create(Ref ref) {
    final argument = this.argument as String;
    return planPlaceSuggestions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlanPlaceSuggestionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planPlaceSuggestionsHash() =>
    r'd4419b505801d9ece074dfee56cffde80f4b36ef';

/// Suggestions for what has been typed. Waits a moment first so a burst of
/// typing asks once, and favours spots near the user. A failure is thrown,
/// so the page can say so and offer Retry.

final class PlanPlaceSuggestionsFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<PlanPlaceSuggestion>>, String> {
  const PlanPlaceSuggestionsFamily._()
    : super(
        retry: null,
        name: r'planPlaceSuggestionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Suggestions for what has been typed. Waits a moment first so a burst of
  /// typing asks once, and favours spots near the user. A failure is thrown,
  /// so the page can say so and offer Retry.

  PlanPlaceSuggestionsProvider call(String query) =>
      PlanPlaceSuggestionsProvider._(argument: query, from: this);

  @override
  String toString() => r'planPlaceSuggestionsProvider';
}
