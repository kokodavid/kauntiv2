import '../core/widgets/app_bottom_nav.dart';
import '../features/onboarding/domain/startup_state.dart';

/// Route paths, and which one each start-up step belongs on.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const homeCounty = '/home-county';
  static const permission = '/permission';
  static const map = '/map';
  static const explore = '/explore';

  static String county(int code) => '/county/$code';
  static String place(String id) => '/place/$id';

  /// The tabs that are live, in shell-branch order.
  static const tabs = [AppNavTab.map, AppNavTab.explore];

  static const _gates = {splash, signIn, homeCounty, permission};

  /// Start-up gating: until onboarding is done, every location goes to
  /// the current step's page; once ready, a gate page goes to Map and
  /// everything else is left alone. Null means stay.
  static String? redirect(StartupStep step, String location) {
    final target = switch (step) {
      StartupStep.splash => splash,
      StartupStep.signIn => signIn,
      StartupStep.homeCounty => homeCounty,
      StartupStep.permission => permission,
      StartupStep.ready => null,
    };
    if (target != null) return location == target ? null : target;
    return _gates.contains(location) ? map : null;
  }
}
