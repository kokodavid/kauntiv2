import '../core/domain/app_feature_flags.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../features/onboarding/domain/startup_state.dart';

/// Route paths and startup/update gates.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const updateRequired = '/update-required';
  static const updateAvailable = '/update-available';
  static const signIn = '/sign-in';
  static const homeCounty = '/home-county';
  static const preferences = '/preferences';
  static const permission = '/permission';
  static const notifications = '/notifications';
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
  static const journeyRecording = '/journey-recording';
  static const savedPlans = '/saved-plans';

  static String county(int code) => '/county/$code';
  static String place(String id) => '/place/$id';
  static String journey(String id) => '/journey/$id';

  /// The tabs that are live, in shell-branch order.
  static const tabs = [
    AppNavTab.map,
    AppNavTab.badges,
    AppNavTab.explore,
    if (AppFeatureFlags.journeys) AppNavTab.journeys,
  ];

  static const _gates = {
    splash,
    signIn,
    homeCounty,
    preferences,
    permission,
    notifications,
  };

  /// Startup gating keeps onboarding and release prompts ahead of app routes.
  /// Null means stay at the requested location.
  static String? redirect(
    StartupStep step,
    String location, {
    bool updateRequired = false,
    bool updateAvailable = false,
  }) {
    final target = switch (step) {
      StartupStep.splash => splash,
      StartupStep.signIn => signIn,
      StartupStep.homeCounty => homeCounty,
      StartupStep.preferences => preferences,
      StartupStep.permission => permission,
      StartupStep.notifications => notifications,
      StartupStep.ready => null,
    };
    if (updateRequired) {
      return location == AppRoutes.updateRequired
          ? null
          : AppRoutes.updateRequired;
    }
    if (updateAvailable && step == StartupStep.ready) {
      return location == AppRoutes.updateAvailable
          ? null
          : AppRoutes.updateAvailable;
    }
    if (location == AppRoutes.updateRequired ||
        location == AppRoutes.updateAvailable) {
      return target ?? map;
    }
    if (target != null) return location == target ? null : target;
    return _gates.contains(location) ? map : null;
  }
}
