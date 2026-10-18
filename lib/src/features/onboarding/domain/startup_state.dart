import '../../../counties/county_paths.dart';
import '../../profile/domain/place_interest.dart';

/// Where start-up has got to. The router maps each step to a route.
enum StartupStep {
  /// The splash is up while assets load and the session is restored.
  splash,
  signIn,

  /// New-user setup step 1 of 3.
  homeCounty,

  /// New-user setup step 2 of 3: what kinds of places the user likes.
  preferences,

  /// New-user setup step 3 of 3. Also shown once, without the step
  /// numbering, to a returning user on a phone that has never been asked
  /// (see [StartupState.isDeviceLocationAsk]).
  permission,

  /// Signed in and past setup (or never needed it).
  ready;

  /// "n of 3" for the three setup steps; null for every other step.
  int? get setupNumber => switch (this) {
    homeCounty => 1,
    preferences => 2,
    permission => 3,
    _ => null,
  };
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
    this.interests = const [],
    this.isSavingInterests = false,
    this.interestsSkipped = false,
    this.isRequestingLocation = false,
    this.isLocationPermanentlyDenied = false,
    this.isDeviceLocationAsk = false,
    this.permissionError,
  });

  final bool splashComplete;

  /// Where onboarding stands once the splash is gone: sign-in, the three
  /// setup steps, or ready. [step] is what's on screen.
  final StartupStep phase;

  /// The saved (or being picked) home county.
  final CountyPath? homeCounty;
  final String? homeCountyError;
  final bool isSavingCounty;

  /// The place interests picked on step 2, in canonical order.
  final List<PlaceInterest> interests;
  final bool isSavingInterests;

  /// True right after "Skip for now" on step 2, while the Undo toast shows
  /// on step 3.
  final bool interestsSkipped;
  final bool isRequestingLocation;
  final bool isLocationPermanentlyDenied;

  /// The permission page is showing for a returning user on a new phone
  /// (not as setup step 3): no "3 of 3", no back button.
  final bool isDeviceLocationAsk;
  final String? permissionError;

  StartupStep get step => splashComplete ? phase : StartupStep.splash;

  StartupState copyWith({
    bool? splashComplete,
    StartupStep? phase,
    CountyPath? Function()? homeCounty,
    String? Function()? homeCountyError,
    bool? isSavingCounty,
    List<PlaceInterest>? interests,
    bool? isSavingInterests,
    bool? interestsSkipped,
    bool? isRequestingLocation,
    bool? isLocationPermanentlyDenied,
    bool? isDeviceLocationAsk,
    String? Function()? permissionError,
  }) => StartupState(
    splashComplete: splashComplete ?? this.splashComplete,
    phase: phase ?? this.phase,
    homeCounty: homeCounty == null ? this.homeCounty : homeCounty(),
    homeCountyError: homeCountyError == null
        ? this.homeCountyError
        : homeCountyError(),
    isSavingCounty: isSavingCounty ?? this.isSavingCounty,
    interests: interests ?? this.interests,
    isSavingInterests: isSavingInterests ?? this.isSavingInterests,
    interestsSkipped: interestsSkipped ?? this.interestsSkipped,
    isRequestingLocation: isRequestingLocation ?? this.isRequestingLocation,
    isLocationPermanentlyDenied:
        isLocationPermanentlyDenied ?? this.isLocationPermanentlyDenied,
    isDeviceLocationAsk: isDeviceLocationAsk ?? this.isDeviceLocationAsk,
    permissionError: permissionError == null
        ? this.permissionError
        : permissionError(),
  );
}
