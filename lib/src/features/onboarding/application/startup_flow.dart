import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../counties/county_paths.dart';
import '../../../services/app_location_permission_service.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/profile_setup_providers.dart';
import '../domain/startup_state.dart';

part 'startup_flow.g.dart';

/// The OS location permission service. Tests override it.
@Riverpod(keepAlive: true)
AppLocationPermissionService locationPermissionService(Ref ref) =>
    const AppLocationPermissionService();

/// Start-up and onboarding: splash (session restore) → sign in → home
/// county → location permission → ready. The router redirects on [step]
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

  /// After sign-in (or a restored session): the saved home county decides
  /// whether to pick one or check permission next.
  Future<void> onSignedIn() async {
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
      // With a county, stay put until the permission check lands, so no
      // other page shows in between.
      phase: county == null ? StartupStep.homeCounty : null,
    );
    if (county != null) await _continueAfterHomeCounty();
  }

  void selectCounty(CountyPath county) => state = state.copyWith(
    homeCounty: () => county,
    homeCountyError: () => null,
  );

  Future<void> saveHomeCounty() async {
    final county = state.homeCounty;
    if (county == null || state.isSavingCounty) return;
    state = state.copyWith(
      isSavingCounty: true,
      homeCountyError: () => null,
    );
    try {
      await ref.read(profileSetupRepositoryProvider).saveHomeCounty(county);
      await _continueAfterHomeCounty();
    } on Object {
      if (!ref.mounted) return;
      state = state.copyWith(
        homeCountyError: () => 'Could not save your home county. Try again.',
      );
    } finally {
      if (ref.mounted) state = state.copyWith(isSavingCounty: false);
    }
  }

  Future<void> _continueAfterHomeCounty() async {
    AppLocationPermissionResult result;
    try {
      result = await _permissions.checkStatus();
    } on Object {
      result = AppLocationPermissionResult.denied;
    }
    if (!ref.mounted) return;
    final granted = result == AppLocationPermissionResult.granted;
    state = state.copyWith(
      phase: granted ? StartupStep.ready : StartupStep.permission,
      isLocationPermanentlyDenied:
          result == AppLocationPermissionResult.permanentlyDenied,
      permissionError: () => null,
    );
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
        state = state.copyWith(
          phase: StartupStep.ready,
          isLocationPermanentlyDenied: false,
          permissionError: () => null,
        );
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
    state = state.copyWith(
      phase: StartupStep.ready,
      isLocationPermanentlyDenied: false,
      permissionError: () => null,
    );
  }
}
