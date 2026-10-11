import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../counties/county_paths.dart';
import '../../../services/app_location_permission_service.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/interests_providers.dart';
import '../../profile/application/profile_settings_providers.dart';
import '../../profile/application/profile_setup_providers.dart';
import '../../profile/domain/place_interest.dart';
import '../domain/startup_state.dart';
import 'setup_progress_providers.dart';

part 'startup_flow.g.dart';

/// The OS location permission service. Tests override it.
@Riverpod(keepAlive: true)
AppLocationPermissionService locationPermissionService(Ref ref) =>
    const AppLocationPermissionService();

/// Start-up and onboarding: splash (session restore) → sign in → then, for
/// a new user only, three setup steps (home county → place interests →
/// location permission) → ready. A returning user, who already has a home
/// county and no setup in progress on this phone, goes straight to ready. The router redirects on [step]
/// (`app/router.dart`); screens call these methods. Ported from the
/// `setState` gate that `app.dart` used to be, with the same rules and
/// copy.
@Riverpod(keepAlive: true)
class StartupFlow extends _$StartupFlow {
  static const _homeCountyCheckFailed =
      'Could not check your saved home county. Pick it again to continue.';

  @override
  StartupState build() => const StartupState();

  AppLocationPermissionService get _permissions =>
      ref.read(locationPermissionServiceProvider);

  /// Splash preload: a signed-in session skips sign-in and goes straight
  /// to its home county / permission check while the splash is still up,
  /// so the sign-in page never flashes.
  Future<void> restoreSession() async {
    if (ref.read(currentUserIdProvider)() == null) return;
    await onSignedIn();
  }

  void completeSplash() => state = state.copyWith(splashComplete: true);

  /// Clear account-specific onboarding state before routing to sign-in.
  void resetAfterSignOut() => state = const StartupState(splashComplete: true);

  String? get _owner => ref.read(currentUserIdProvider)();

  Future<bool> _setupInProgress() async {
    final owner = _owner;
    if (owner == null) return false;
    return ref.read(setupProgressStoreProvider).isInProgress(owner);
  }

  Future<void> _markSetupInProgress(bool value) async {
    final owner = _owner;
    if (owner == null) return;
    await ref.read(setupProgressStoreProvider).setInProgress(owner, value);
  }

  /// After sign-in (or a restored session): decides, before anything is
  /// drawn, whether this is a returning user (straight to ready) or a new
  /// one who still has setup to do (and which step to resume at).
  Future<void> onSignedIn() async {
    // A county remembered on this phone is trusted at once, so a returning
    // user starts instantly and offline. The server copy is re-read quietly
    // afterwards in case it changed elsewhere.
    CountyPath? remembered;
    try {
      remembered = await ref
          .read(profileSetupRepositoryProvider)
          .cachedHomeCounty();
    } on Object {
      remembered = null;
    }
    if (!ref.mounted) return;
    final inProgress = await _setupInProgress();
    if (!ref.mounted) return;
    if (remembered != null) {
      state = state.copyWith(
        homeCounty: () => remembered,
        homeCountyError: () => null,
        permissionError: () => null,
      );
      unawaited(_refreshHomeCounty());
      unawaited(_syncInterests());
      await (inProgress ? _continueSetup() : _finishSetup());
      return;
    }

    CountyPath? county;
    String? error;
    try {
      county = await ref.read(profileSetupRepositoryProvider).fetchHomeCounty();
    } on Object {
      error = _homeCountyCheckFailed;
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      homeCounty: () => county,
      homeCountyError: () => error,
      permissionError: () => null,
      // With a county, stay put until the next step is decided, so no other
      // page shows in between.
      phase: county == null ? StartupStep.homeCounty : null,
    );
    if (county != null) {
      unawaited(_syncInterests());
      await (inProgress ? _continueSetup() : _finishSetup());
    } else if (error == null) {
      // Confirmed new user: setup has started.
      await _markSetupInProgress(true);
    }
  }

  /// Background re-read of the saved county. Failures (offline, slow) are
  /// ignored: the remembered county keeps working.
  Future<void> _refreshHomeCounty() async {
    try {
      final latest = await ref
          .read(profileSetupRepositoryProvider)
          .fetchHomeCounty();
      if (!ref.mounted || latest == null || latest == state.homeCounty) return;
      state = state.copyWith(homeCounty: () => latest);
    } on Object {
      // Keep using the remembered county.
    }
  }

  void selectCounty(CountyPath county) => state = state.copyWith(
    homeCounty: () => county,
    homeCountyError: () => null,
  );

  Future<void> saveHomeCounty() async {
    final county = state.homeCounty;
    if (county == null || state.isSavingCounty) return;
    state = state.copyWith(isSavingCounty: true, homeCountyError: () => null);
    try {
      await ref.read(profileSetupRepositoryProvider).saveHomeCounty(county);
      await _markSetupInProgress(true);
      await _continueSetup();
    } on Object {
      if (!ref.mounted) return;
      state = state.copyWith(
        homeCountyError: () => 'Could not save your home county. Try again.',
      );
    } finally {
      if (ref.mounted) state = state.copyWith(isSavingCounty: false);
    }
  }

  /// Resume setup at the first unfinished step after the home county:
  /// interests not answered → step 2, otherwise on to the permission.
  Future<void> _continueSetup() async {
    InterestsAnswer? answer;
    try {
      final repository = ref.read(interestsRepositoryProvider);
      answer = await repository.cached();
      answer ??= await repository.fetch();
    } on Object {
      answer = null;
    }
    if (!ref.mounted) return;
    if (answer == null || !answer.completed) {
      state = state.copyWith(
        phase: StartupStep.preferences,
        interests: answer?.interests ?? state.interests,
        permissionError: () => null,
      );
      return;
    }
    state = state.copyWith(interests: answer.interests);
    await _continuePastInterests();
  }

  Future<void> _syncInterests() async {
    try {
      await ref.read(interestsRepositoryProvider).syncPending();
    } on Object {
      // Sent next time.
    }
  }

  void toggleInterest(PlaceInterest interest) {
    final next = state.interests.contains(interest)
        ? [
            for (final i in state.interests)
              if (i != interest) i,
          ]
        : PlaceInterest.fromKeys([
            ...state.interests.map((i) => i.key),
            interest.key,
          ]);
    state = state.copyWith(interests: next);
  }

  /// Step 2's Continue: remember the picks, then on to the permission.
  Future<void> continueFromInterests() async {
    if (state.isSavingInterests) return;
    await _answerInterests(state.interests, skipped: false);
  }

  /// Step 2's "Skip for now": saves an empty answer so it is never asked
  /// again in setup; step 3 shows an Undo toast.
  Future<void> skipInterests() async {
    if (state.isSavingInterests) return;
    state = state.copyWith(interests: const []);
    await _answerInterests(const [], skipped: true);
  }

  Future<void> _answerInterests(
    List<PlaceInterest> picks, {
    required bool skipped,
  }) async {
    state = state.copyWith(isSavingInterests: true);
    try {
      await ref
          .read(interestsRepositoryProvider)
          .save(InterestsAnswer(interests: picks, completed: true));
    } on Object {
      // The answer is kept on the phone; setup carries on regardless.
    }
    if (!ref.mounted) return;
    state = state.copyWith(isSavingInterests: false, interestsSkipped: skipped);
    await _continuePastInterests();
  }

  /// The Undo on the skip toast: back to step 2 with the question open.
  Future<void> undoInterestsSkip() async {
    state = state.copyWith(
      phase: StartupStep.preferences,
      interestsSkipped: false,
      permissionError: () => null,
    );
    try {
      await ref
          .read(interestsRepositoryProvider)
          .save(InterestsAnswer(interests: state.interests, completed: false));
    } on Object {
      // Still reopens; the answer is re-saved on Continue.
    }
  }

  void dismissInterestsToast() {
    if (state.interestsSkipped) {
      state = state.copyWith(interestsSkipped: false);
    }
  }

  /// Back one setup step; picks and the saved county are kept.
  void back() {
    final previous = switch (state.phase) {
      StartupStep.permission => StartupStep.preferences,
      StartupStep.preferences => StartupStep.homeCounty,
      final other => other,
    };
    if (previous == state.phase) return;
    state = state.copyWith(
      phase: previous,
      interestsSkipped: false,
      permissionError: () => null,
    );
  }

  /// Past step 2: the permission step, or straight to ready when location
  /// is already granted.
  Future<void> _continuePastInterests() async {
    AppLocationPermissionResult result;
    try {
      result = await _permissions.checkStatus();
    } on Object {
      result = AppLocationPermissionResult.denied;
    }
    if (!ref.mounted) return;
    if (result == AppLocationPermissionResult.granted) {
      await _finishSetup();
      return;
    }
    state = state.copyWith(
      phase: StartupStep.permission,
      isLocationPermanentlyDenied:
          result == AppLocationPermissionResult.permanentlyDenied,
      permissionError: () => null,
    );
  }

  /// Setup is over: clear the in-progress flag and open Home.
  Future<void> _finishSetup() async {
    await _markSetupInProgress(false);
    if (!ref.mounted) return;
    state = state.copyWith(
      phase: StartupStep.ready,
      isLocationPermanentlyDenied: false,
      permissionError: () => null,
    );
  }

  /// Step 3's "Not now" (and "Continue in manual mode"): Home in manual
  /// mode. Location can be turned on later from Settings.
  Future<void> skipLocation() async {
    if (state.isRequestingLocation) return;
    try {
      await ref.read(profileSettingsRepositoryProvider).update({
        'location_mode': 'manual',
      });
    } on Object {
      // The mode is a preference; Home opens either way.
    }
    if (!ref.mounted) return;
    await _finishSetup();
  }

  /// The permission page's button: the OS prompt, or the OS settings once
  /// the prompt can't be shown again.
  Future<void> enableLocation() async {
    if (state.isLocationPermanentlyDenied) {
      await _permissions.openSettings();
      return;
    }
    await _requestLocation();
  }

  Future<void> _requestLocation() async {
    state = state.copyWith(
      isRequestingLocation: true,
      permissionError: () => null,
    );
    try {
      final result = await _permissions.requestLocationAccess();
      if (!ref.mounted) return;
      if (result == AppLocationPermissionResult.granted) {
        await _finishSetup();
        return;
      }
      state = state.copyWith(
        isLocationPermanentlyDenied:
            result == AppLocationPermissionResult.permanentlyDenied,
        permissionError: () => switch (result) {
          AppLocationPermissionResult.permanentlyDenied =>
            'Location permission is disabled. Open settings and allow it to '
                'unlock badges automatically.',
          AppLocationPermissionResult.restricted =>
            'Location permission is restricted on this device.',
          AppLocationPermissionResult.denied =>
            'Location permission is needed to unlock county badges '
                'automatically.',
          AppLocationPermissionResult.granted => null,
        },
      );
    } on Object {
      if (ref.mounted) {
        state = state.copyWith(
          permissionError: () =>
              'Could not request location permission. Try again.',
        );
      }
    } finally {
      if (ref.mounted) state = state.copyWith(isRequestingLocation: false);
    }
  }

  /// Back from the OS settings: carry on if permission was granted there.
  Future<void> recheckPermission() async {
    if (!state.isLocationPermanentlyDenied) return;
    final result = await _permissions.checkStatus();
    if (!ref.mounted || result != AppLocationPermissionResult.granted) return;
    await _finishSetup();
  }
}
