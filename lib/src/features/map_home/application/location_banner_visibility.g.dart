// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_banner_visibility.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether Home may still show the location banner in the stat card's place.
/// It starts visible and is switched off for the rest of the app launch once
/// the banner has had its few seconds, so the next cold start shows it again
/// while a problem remains. Held for the life of the app, not per screen,
/// so coming back to Home doesn't replay it.

@ProviderFor(LocationBannerVisible)
const locationBannerVisibleProvider = LocationBannerVisibleProvider._();

/// Whether Home may still show the location banner in the stat card's place.
/// It starts visible and is switched off for the rest of the app launch once
/// the banner has had its few seconds, so the next cold start shows it again
/// while a problem remains. Held for the life of the app, not per screen,
/// so coming back to Home doesn't replay it.
final class LocationBannerVisibleProvider
    extends $NotifierProvider<LocationBannerVisible, bool> {
  /// Whether Home may still show the location banner in the stat card's place.
  /// It starts visible and is switched off for the rest of the app launch once
  /// the banner has had its few seconds, so the next cold start shows it again
  /// while a problem remains. Held for the life of the app, not per screen,
  /// so coming back to Home doesn't replay it.
  const LocationBannerVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationBannerVisibleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationBannerVisibleHash();

  @$internal
  @override
  LocationBannerVisible create() => LocationBannerVisible();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$locationBannerVisibleHash() =>
    r'0000000000000000000000000000000000000000';

/// Whether Home may still show the location banner in the stat card's place.
/// It starts visible and is switched off for the rest of the app launch once
/// the banner has had its few seconds, so the next cold start shows it again
/// while a problem remains. Held for the life of the app, not per screen,
/// so coming back to Home doesn't replay it.

abstract class _$LocationBannerVisible extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
