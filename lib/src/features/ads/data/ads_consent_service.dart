import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Consent and start-up for the ad SDK, through Google's User Messaging
/// Platform: it shows the EEA/UK consent form (and, on iOS, the tracking
/// message set up in AdMob) only where it is required.
abstract interface class AdsConsentService {
  /// Gathers consent, then starts the ad SDK. True when ads may be
  /// requested. Never throws.
  Future<bool> gather();

  /// Whether the user must be able to change their choice (the "Ad
  /// choices" row in Settings).
  Future<bool> privacyOptionsRequired();

  Future<void> showPrivacyOptions();
}

class UmpAdsConsentService implements AdsConsentService {
  const UmpAdsConsentService();

  @override
  Future<bool> gather() async {
    try {
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!done.isCompleted) done.complete();
        }),
        (_) {
          // Offline or a form error: an earlier session's consent may still
          // allow ads, which canRequestAds() reports.
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future;
      if (!await ConsentInformation.instance.canRequestAds()) return false;
      await MobileAds.instance.initialize();
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    try {
      final done = Completer<void>();
      unawaited(
        ConsentForm.showPrivacyOptionsForm((_) {
          if (!done.isCompleted) done.complete();
        }),
      );
      await done.future;
    } on Object {
      // The form is optional; nothing to recover.
    }
  }
}
