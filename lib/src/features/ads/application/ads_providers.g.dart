// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ads_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The dashboard's ads switch. Null without Supabase.

@ProviderFor(adsFlagRepository)
const adsFlagRepositoryProvider = AdsFlagRepositoryProvider._();

/// The dashboard's ads switch. Null without Supabase.

final class AdsFlagRepositoryProvider
    extends
        $FunctionalProvider<
          AdsFlagRepository?,
          AdsFlagRepository?,
          AdsFlagRepository?
        >
    with $Provider<AdsFlagRepository?> {
  /// The dashboard's ads switch. Null without Supabase.
  const AdsFlagRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adsFlagRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adsFlagRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdsFlagRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdsFlagRepository? create(Ref ref) {
    return adsFlagRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdsFlagRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdsFlagRepository?>(value),
    );
  }
}

String _$adsFlagRepositoryHash() => r'6ac0b253047f6bde964b521e995ea2a98593f2d1';

/// Whether the dashboard has ads switched on. Read once at start-up; any
/// failure (offline, no config) means off, so nothing shows by accident.

@ProviderFor(adsFlag)
const adsFlagProvider = AdsFlagProvider._();

/// Whether the dashboard has ads switched on. Read once at start-up; any
/// failure (offline, no config) means off, so nothing shows by accident.

final class AdsFlagProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the dashboard has ads switched on. Read once at start-up; any
  /// failure (offline, no config) means off, so nothing shows by accident.
  const AdsFlagProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adsFlagProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adsFlagHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return adsFlag(ref);
  }
}

String _$adsFlagHash() => r'7aadb905bed242a210b0a4ab306e6f9103740ce0';

@ProviderFor(adsProCache)
const adsProCacheProvider = AdsProCacheProvider._();

final class AdsProCacheProvider
    extends $FunctionalProvider<AdsProCache, AdsProCache, AdsProCache>
    with $Provider<AdsProCache> {
  const AdsProCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adsProCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adsProCacheHash();

  @$internal
  @override
  $ProviderElement<AdsProCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdsProCache create(Ref ref) {
    return adsProCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdsProCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdsProCache>(value),
    );
  }
}

String _$adsProCacheHash() => r'8379fe40e9c38e4299076f1a082e9d1ad4fe33d8';

@ProviderFor(adsConsentService)
const adsConsentServiceProvider = AdsConsentServiceProvider._();

final class AdsConsentServiceProvider
    extends
        $FunctionalProvider<
          AdsConsentService,
          AdsConsentService,
          AdsConsentService
        >
    with $Provider<AdsConsentService> {
  const AdsConsentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adsConsentServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adsConsentServiceHash();

  @$internal
  @override
  $ProviderElement<AdsConsentService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdsConsentService create(Ref ref) {
    return adsConsentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdsConsentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdsConsentService>(value),
    );
  }
}

String _$adsConsentServiceHash() => r'7bed54bae171d40fe23d53351bd099cf84909180';

/// Whether the ads consent step (UMP, and iOS tracking) is finished and the
/// ad SDK is started. Only ever begun for a free audience with the dashboard
/// switch on, so Pro users never load the SDK.

@ProviderFor(AdsConsent)
const adsConsentProvider = AdsConsentProvider._();

/// Whether the ads consent step (UMP, and iOS tracking) is finished and the
/// ad SDK is started. Only ever begun for a free audience with the dashboard
/// switch on, so Pro users never load the SDK.
final class AdsConsentProvider extends $NotifierProvider<AdsConsent, bool> {
  /// Whether the ads consent step (UMP, and iOS tracking) is finished and the
  /// ad SDK is started. Only ever begun for a free audience with the dashboard
  /// switch on, so Pro users never load the SDK.
  const AdsConsentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adsConsentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adsConsentHash();

  @$internal
  @override
  AdsConsent create() => AdsConsent();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$adsConsentHash() => r'0ac50ea7ecff7d5119f0c6966da4c48b8c0328a1';

/// Whether the ads consent step (UMP, and iOS tracking) is finished and the
/// ad SDK is started. Only ever begun for a free audience with the dashboard
/// switch on, so Pro users never load the SDK.

abstract class _$AdsConsent extends $Notifier<bool> {
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

/// Whether Settings should offer "Ad choices" (the user may change their
/// consent). Re-checked once consent has been gathered.

@ProviderFor(adsPrivacyOptionsRequired)
const adsPrivacyOptionsRequiredProvider = AdsPrivacyOptionsRequiredProvider._();

/// Whether Settings should offer "Ad choices" (the user may change their
/// consent). Re-checked once consent has been gathered.

final class AdsPrivacyOptionsRequiredProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether Settings should offer "Ad choices" (the user may change their
  /// consent). Re-checked once consent has been gathered.
  const AdsPrivacyOptionsRequiredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adsPrivacyOptionsRequiredProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adsPrivacyOptionsRequiredHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return adsPrivacyOptionsRequired(ref);
  }
}

String _$adsPrivacyOptionsRequiredHash() =>
    r'aaeaab402c5927a3f06220ebfc3fb2a4441ae617';

/// The native ad unit for this build, or null when there is none (prod
/// before its units exist), so no ad is requested.

@ProviderFor(nativeAdUnit)
const nativeAdUnitProvider = NativeAdUnitProvider._();

/// The native ad unit for this build, or null when there is none (prod
/// before its units exist), so no ad is requested.

final class NativeAdUnitProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The native ad unit for this build, or null when there is none (prod
  /// before its units exist), so no ad is requested.
  const NativeAdUnitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nativeAdUnitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nativeAdUnitHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return nativeAdUnit(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$nativeAdUnitHash() => r'5e61b97e9d48ebc303b4cfea75f687d046119f61';

/// Who is looking: signed out is free, signed in is the cached Pro status
/// until the server confirms it, and unknown until either exists.

@ProviderFor(AdsAudienceController)
const adsAudienceControllerProvider = AdsAudienceControllerProvider._();

/// Who is looking: signed out is free, signed in is the cached Pro status
/// until the server confirms it, and unknown until either exists.
final class AdsAudienceControllerProvider
    extends $NotifierProvider<AdsAudienceController, AdsAudience> {
  /// Who is looking: signed out is free, signed in is the cached Pro status
  /// until the server confirms it, and unknown until either exists.
  const AdsAudienceControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adsAudienceControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adsAudienceControllerHash();

  @$internal
  @override
  AdsAudienceController create() => AdsAudienceController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdsAudience value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdsAudience>(value),
    );
  }
}

String _$adsAudienceControllerHash() =>
    r'a813ef96b0446c35083a6b076d245276a03bc559';

/// Who is looking: signed out is free, signed in is the cached Pro status
/// until the server confirms it, and unknown until either exists.

abstract class _$AdsAudienceController extends $Notifier<AdsAudience> {
  AdsAudience build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AdsAudience, AdsAudience>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AdsAudience, AdsAudience>,
              AdsAudience,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// The banner unit for this build (lists), or null when there is none.

@ProviderFor(bannerAdUnit)
const bannerAdUnitProvider = BannerAdUnitProvider._();

/// The banner unit for this build (lists), or null when there is none.

final class BannerAdUnitProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The banner unit for this build (lists), or null when there is none.
  const BannerAdUnitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bannerAdUnitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bannerAdUnitHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return bannerAdUnit(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$bannerAdUnitHash() => r'06043860b28e9be78893d593738a0799bc06e82a';

/// Whether the app wants ads at all right now: the dashboard switch is on
/// and this is a free audience. Consent is gathered when this turns true.

@ProviderFor(adsWanted)
const adsWantedProvider = AdsWantedProvider._();

/// Whether the app wants ads at all right now: the dashboard switch is on
/// and this is a free audience. Consent is gathered when this turns true.

final class AdsWantedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the app wants ads at all right now: the dashboard switch is on
  /// and this is a free audience. Consent is gathered when this turns true.
  const AdsWantedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adsWantedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adsWantedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return adsWanted(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$adsWantedHash() => r'ead33a941afb3f099461c75892a98088b46973ee';

/// True when an ad may be shown right now. Every ad widget reads this.

@ProviderFor(showAds)
const showAdsProvider = ShowAdsProvider._();

/// True when an ad may be shown right now. Every ad widget reads this.

final class ShowAdsProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// True when an ad may be shown right now. Every ad widget reads this.
  const ShowAdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showAdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showAdsHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return showAds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showAdsHash() => r'8725179c07b6d4167db43623d6882ba80fcba9f5';
