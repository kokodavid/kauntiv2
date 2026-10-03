// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_stats_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tripStatsRepository)
const tripStatsRepositoryProvider = TripStatsRepositoryProvider._();

final class TripStatsRepositoryProvider
    extends
        $FunctionalProvider<
          TripStatsRepository?,
          TripStatsRepository?,
          TripStatsRepository?
        >
    with $Provider<TripStatsRepository?> {
  const TripStatsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripStatsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripStatsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TripStatsRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TripStatsRepository? create(Ref ref) {
    return tripStatsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripStatsRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripStatsRepository?>(value),
    );
  }
}

String _$tripStatsRepositoryHash() =>
    r'1c4e8b2f9a6d3057c1e4b8f2a9d6c3057e1b4f82';

/// The signed-in account's Trip count / distance stats, for Profile's
/// progress card. Reloads when the account changes.

@ProviderFor(tripStats)
const tripStatsProvider = TripStatsProvider._();

/// The signed-in account's Trip count / distance stats, for Profile's
/// progress card. Reloads when the account changes.

final class TripStatsProvider
    extends
        $FunctionalProvider<AsyncValue<TripStats>, TripStats, FutureOr<TripStats>>
    with $FutureModifier<TripStats>, $FutureProvider<TripStats> {
  /// The signed-in account's Trip count / distance stats, for Profile's
  /// progress card. Reloads when the account changes.
  const TripStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripStatsHash();

  @$internal
  @override
  $FutureProviderElement<TripStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TripStats> create(Ref ref) {
    return tripStats(ref);
  }
}

String _$tripStatsHash() => r'9b3d6f1a8c4e2057b3d6f1a8c4e2957b3d6f1a8';
