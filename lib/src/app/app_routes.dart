import '../core/domain/app_feature_flags.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../features/onboarding/domain/startup_state.dart';

/// Route paths and startup/update gates.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const updateRequired = '/update-required';
  static const signIn = '/sign-in';
  static const homeCounty = '/home-county';
  static const preferences = '/preferences';
  static const username = '/username';
  static const permission = '/permission';
  static const map = '/map';
  static const badges = '/badges';
  static const explore = '/explore';
  static const journeys = '/journeys';
  static const profile = '/profile';
  static const settings = '/settings';
  static const interests = '/interests';
  static const feedback = '/feedback';
  static const feedbackReports = '/feedback/reports';
  static const myPhotos = '/my-photos';
  static const locationDiagnostics = '/location-diagnostics';
  static const pushStatus = '/push-status';
  static const journeyRecording = '/journey-recording';
  static const savedPlans = '/saved-plans';
  static const upgrade = '/upgrade';

  static String county(int code) => '/county/$code';
  static String place(String id) => '/place/$id';
  static String journey(String id) => '/journey/$id';
  static String plan(String id) => '/plan/$id';
  static String join(String code) => '/p/$code';

  /// The tabs that are live, in shell-branch order.
  static const tabs = [
    AppNavTab.map,
    AppNavTab.badges,
    AppNavTab.explore,
    if (AppFeatureFlags.journeys) AppNavTab.journeys,
  ];

  /// The invite code in a `/p/<code>` location, or null.
  static String? inviteCode(String location) {
    final match = RegExp(r'^/p/([^/?#]+)').firstMatch(location);
    return match?.group(1);
  }

  static const _gates = {
    splash,
    signIn,
    homeCounty,
    preferences,
    username,
    permission,
  };

  /// Startup gating keeps onboarding and release prompts ahead of app routes.
  /// Null means stay at the requested location. An invite link opened before
  /// start-up is done is remembered by the caller and passed back here as
  /// [pendingInvite], so it opens once the user lands on the app.
  static String? redirect(
    StartupStep step,
    String location, {
    bool updateRequired = false,
    String? pendingInvite,
  }) {
    final target = switch (step) {
      StartupStep.splash => splash,
      StartupStep.signIn => signIn,
      StartupStep.homeCounty => homeCounty,
      StartupStep.preferences => preferences,
      StartupStep.username => username,
      StartupStep.permission => permission,
      StartupStep.ready => null,
    };
    if (updateRequired) {
      return location == AppRoutes.updateRequired
          ? null
          : AppRoutes.updateRequired;
    }
    if (location == AppRoutes.updateRequired) {
      return target ?? map;
    }
    if (target != null) return location == target ? null : target;
    if (_gates.contains(location)) {
      return pendingInvite == null ? map : join(pendingInvite);
    }
    return null;
  }
}
