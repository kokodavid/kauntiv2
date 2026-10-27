import '../../journeys/domain/pro_status.dart';

/// Who is looking at the app, as far as ads are concerned.
enum AdsAudience {
  /// Signed in, and Pro has not been confirmed either way yet.
  unknown,

  /// Signed out, or signed in without an active Pro.
  free,

  /// Holds an active Pro. Never sees ads.
  pro,
}

/// The one rule for whether an ad may be shown.
///
/// Ads are for anyone who has not subscribed to Pro. When Pro is not known
/// yet (offline on a fresh install, still loading) the answer is no: a
/// wrong guess costs a few missed ads, never a paying user seeing one.
abstract final class AdsGate {
  /// The audience for a cached or live [status] at [now]. A null [status]
  /// means "not checked yet" for a signed-in user.
  static AdsAudience audienceFor(ProStatus? status, DateTime now) {
    if (status == null) return AdsAudience.unknown;
    return status.allowsStartAt(now) ? AdsAudience.pro : AdsAudience.free;
  }

  static bool shouldShow({
    required AdsAudience audience,
    required bool consentDone,
    required bool enabled,
  }) => enabled && consentDone && audience == AdsAudience.free;
}
