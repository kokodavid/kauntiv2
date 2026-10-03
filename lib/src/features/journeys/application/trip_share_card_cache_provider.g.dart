// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_share_card_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tripShareCardCacheAccess)
const tripShareCardCacheAccessProvider = TripShareCardCacheAccessProvider._();

final class TripShareCardCacheAccessProvider
    extends
        $FunctionalProvider<
          TripShareCardCacheAccess,
          TripShareCardCacheAccess,
          TripShareCardCacheAccess
        >
    with $Provider<TripShareCardCacheAccess> {
  const TripShareCardCacheAccessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripShareCardCacheAccessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripShareCardCacheAccessHash();

  @$internal
  @override
  $ProviderElement<TripShareCardCacheAccess> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TripShareCardCacheAccess create(Ref ref) {
    return tripShareCardCacheAccess(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripShareCardCacheAccess value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripShareCardCacheAccess>(value),
    );
  }
}

String _$tripShareCardCacheAccessHash() =>
    r'c4713111ea4100eaba90c80b86ff941a770aa794';
