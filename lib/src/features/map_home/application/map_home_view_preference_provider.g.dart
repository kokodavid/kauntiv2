// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_home_view_preference_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mapHomeViewPreference)
const mapHomeViewPreferenceProvider = MapHomeViewPreferenceProvider._();

final class MapHomeViewPreferenceProvider
    extends
        $FunctionalProvider<
          MapHomeViewPreference,
          MapHomeViewPreference,
          MapHomeViewPreference
        >
    with $Provider<MapHomeViewPreference> {
  const MapHomeViewPreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapHomeViewPreferenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapHomeViewPreferenceHash();

  @$internal
  @override
  $ProviderElement<MapHomeViewPreference> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MapHomeViewPreference create(Ref ref) {
    return mapHomeViewPreference(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapHomeViewPreference value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapHomeViewPreference>(value),
    );
  }
}

String _$mapHomeViewPreferenceHash() =>
    r'89f6a2c3973e1e2148d792cb52a432fc7c166f79';
