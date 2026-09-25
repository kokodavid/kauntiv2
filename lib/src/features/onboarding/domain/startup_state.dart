import '../../../counties/county_paths.dart';

/// Where start-up has got to. The router maps each step to a route.
enum StartupStep {
  /// The splash is up while assets load and the session is restored.
  splash,
  signIn,
  homeCounty,
  permission,

  /// Signed in, home county saved, background location granted.
  ready,
}

/// Start-up and onboarding state (formerly the fields of `app.dart`'s
/// `_StartupGate`).
class StartupState {
  const StartupState({
    this.splashComplete = false,
    this.phase = StartupStep.signIn,
    this.homeCounty,
    this.homeCountyError,
    this.isSavingCounty = false,
    this.isRequestingLocation = false,
    this.isLocationPermanentlyDenied = false,
    this.permissionError,
  });

  final bool splashComplete;

  /// Where onboarding stands once the splash is gone: sign-in, home
  /// county, permission or ready. [step] is what's on screen.
  final StartupStep phase;

  /// The saved (or being picked) home county.
  final CountyPath? homeCounty;
  final String? homeCountyError;
  final bool isSavingCounty;
  final bool isRequestingLocation;
  final bool isLocationPermanentlyDenied;
  final String? permissionError;

  StartupStep get step => splashComplete ? phase : StartupStep.splash;

  StartupState copyWith({
    bool? splashComplete,
    StartupStep? phase,
    CountyPath? Function()? homeCounty,
    String? Function()? homeCountyError,
    bool? isSavingCounty,
    bool? isRequestingLocation,
    bool? isLocationPermanentlyDenied,
    String? Function()? permissionError,
  }) => StartupState(
    splashComplete: splashComplete ?? this.splashComplete,
    phase: phase ?? this.phase,
    homeCounty: homeCounty == null ? this.homeCounty : homeCounty(),
    homeCountyError: homeCountyError == null
        ? this.homeCountyError
        : homeCountyError(),
    isSavingCounty: isSavingCounty ?? this.isSavingCounty,
    isRequestingLocation: isRequestingLocation ?? this.isRequestingLocation,
    isLocationPermanentlyDenied:
        isLocationPermanentlyDenied ?? this.isLocationPermanentlyDenied,
    permissionError: permissionError == null
        ? this.permissionError
        : permissionError(),
  );
}
