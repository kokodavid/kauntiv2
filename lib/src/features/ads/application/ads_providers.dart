import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../config/app_environment.dart';
import '../../../core/services/app_config_provider.dart';
import '../../../core/services/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../journeys/application/journey_entitlement.dart';
import '../data/ads_consent_service.dart';
import '../data/ads_flag_repository.dart';
import '../data/ads_pro_cache.dart';
import '../domain/ad_units.dart';
import '../domain/ads_gate.dart';

part 'ads_providers.g.dart';

/// The dashboard's ads switch. Null without Supabase.
@Riverpod(keepAlive: true)
AdsFlagRepository? adsFlagRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseAdsFlagRepository(client);
}

/// Whether the dashboard has ads switched on. Read once at start-up; any
/// failure (offline, no config) means off, so nothing shows by accident.
@Riverpod(keepAlive: true)
Future<bool> adsFlag(Ref ref) async {
  final repository = ref.watch(adsFlagRepositoryProvider);
  if (repository == null) return false;
  try {
    return await repository.isEnabled().timeout(const Duration(seconds: 5));
  } on Object {
    return false;
  }
}

@Riverpod(keepAlive: true)
AdsProCache adsProCache(Ref ref) => const SharedPreferencesAdsProCache();

@Riverpod(keepAlive: true)
AdsConsentService adsConsentService(Ref ref) => const UmpAdsConsentService();

/// Whether the ads consent step (UMP, and iOS tracking) is finished and the
/// ad SDK is started. Only ever begun for a free audience with the dashboard
/// switch on, so Pro users never load the SDK.
@Riverpod(keepAlive: true)
class AdsConsent extends _$AdsConsent {
  bool _running = false;

  @override
  bool build() => false;

  Future<void> gather() async {
    if (state || _running) return;
    _running = true;
    try {
      final ok = await ref.read(adsConsentServiceProvider).gather();
      if (ref.mounted && ok) state = true;
    } finally {
      _running = false;
    }
  }

  Future<void> showPrivacyOptions() =>
      ref.read(adsConsentServiceProvider).showPrivacyOptions();
}

/// Whether Settings should offer "Ad choices" (the user may change their
/// consent). Re-checked once consent has been gathered.
@riverpod
Future<bool> adsPrivacyOptionsRequired(Ref ref) {
  ref.watch(adsConsentProvider);
  return ref.watch(adsConsentServiceProvider).privacyOptionsRequired();
}

/// The native ad unit for this build, or null when there is none (prod
/// before its units exist), so no ad is requested.
@riverpod
String? nativeAdUnit(Ref ref) => AdUnits.native(
  isIos: defaultTargetPlatform == TargetPlatform.iOS,
  prod: ref.watch(appConfigProvider).environment == AppEnvironment.prod,
);

/// Who is looking: signed out is free, signed in is the cached Pro status
/// until the server confirms it, and unknown until either exists.
@Riverpod(keepAlive: true)
class AdsAudienceController extends _$AdsAudienceController {
  @override
  AdsAudience build() {
    final auth = ref.watch(authUserIdProvider);
    if (auth.isLoading && !auth.hasValue) return AdsAudience.unknown;
    final owner = auth.value;
    if (owner == null) return AdsAudience.free;

    ref.listen(journeyEntitlementProvider, (_, live) {
      if (live == null) return;
      unawaited(ref.read(adsProCacheProvider).write(owner, live));
      state = AdsGate.audienceFor(live, DateTime.now());
    });
    unawaited(_start(owner));
    return AdsAudience.unknown;
  }

  Future<void> _start(String owner) async {
    final cached = await ref.read(adsProCacheProvider).read(owner);
    if (!ref.mounted) return;
    final live = ref.read(journeyEntitlementProvider);
    if (live == null && cached != null) {
      state = AdsGate.audienceFor(cached, DateTime.now());
    }
    try {
      await ref.read(journeyEntitlementProvider.notifier).refreshStatus();
    } on Object {
      // Offline: keep whatever the cache said.
    }
  }
}

/// The banner unit for this build (lists), or null when there is none.
@riverpod
String? bannerAdUnit(Ref ref) => AdUnits.banner(
  isIos: defaultTargetPlatform == TargetPlatform.iOS,
  prod: ref.watch(appConfigProvider).environment == AppEnvironment.prod,
);

/// Whether the app wants ads at all right now: the dashboard switch is on
/// and this is a free audience. Consent is gathered when this turns true.
@riverpod
bool adsWanted(Ref ref) => AdsGate.shouldShow(
  audience: ref.watch(adsAudienceControllerProvider),
  consentDone: true,
  enabled: ref.watch(adsFlagProvider).value ?? false,
);

/// True when an ad may be shown right now. Every ad widget reads this.
@riverpod
bool showAds(Ref ref) =>
    ref.watch(adsWantedProvider) && ref.watch(adsConsentProvider);
