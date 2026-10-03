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
    r'a82f774879ded32cbf3933f4a3c89414e5570b65';

/// The signed-in account's Trip count / distance stats, for Profile's
/// progress card. Reloads when the account changes.

@ProviderFor(tripStats)
const tripStatsProvider = TripStatsProvider._();

/// The signed-in account's Trip count / distance stats, for Profile's
/// progress card. Reloads when the account changes.

final class TripStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<TripStats>,
          TripStats,
          FutureOr<TripStats>
        >
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
  $FutureProviderElement<TripStats> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TripStats> create(Ref ref) {
    return tripStats(ref);
  }
}

String _$tripStatsHash() => r'0c564bdd8914bd9f3b03762e5083918181eea6e6';
