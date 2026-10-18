// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_nearby_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The places nearest the traveller, ranked by exactly the function Home's
/// sheet uses ([MapHomeNearbyPlaces.nearest]): every listed place, device
/// location, and the same lean toward the traveller's interests. Empty when
/// there is no fix in Kenya, as on Home.

@ProviderFor(exploreNearby)
const exploreNearbyProvider = ExploreNearbyProvider._();

/// The places nearest the traveller, ranked by exactly the function Home's
/// sheet uses ([MapHomeNearbyPlaces.nearest]): every listed place, device
/// location, and the same lean toward the traveller's interests. Empty when
/// there is no fix in Kenya, as on Home.

final class ExploreNearbyProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ExploreEntry>>,
          List<ExploreEntry>,
          FutureOr<List<ExploreEntry>>
        >
    with
        $FutureModifier<List<ExploreEntry>>,
        $FutureProvider<List<ExploreEntry>> {
  /// The places nearest the traveller, ranked by exactly the function Home's
  /// sheet uses ([MapHomeNearbyPlaces.nearest]): every listed place, device
  /// location, and the same lean toward the traveller's interests. Empty when
  /// there is no fix in Kenya, as on Home.
  const ExploreNearbyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreNearbyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreNearbyHash();

  @$internal
  @override
  $FutureProviderElement<List<ExploreEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ExploreEntry>> create(Ref ref) {
    return exploreNearby(ref);
  }
}

String _$exploreNearbyHash() => r'44f8d1c5cfc78a58ace403a45ccd7ef0c07d2eba';
