part of 'startup_flow.dart';

mixin _StartupPermissionSteps on _$StartupFlow {
  AppLocationPermissionService get _permissions;
  Future<void> _finishSetup();

  /// A signed-in user who is past setup: Home, unless this phone has never
  /// been asked for location. Permission belongs to the phone, not the
  /// account, so someone signing in on a new phone (or after a reinstall)
  /// sees the permission page once, without the setup numbering. It is
  /// never a gate: "Not now", or just closing the app, is remembered and the
  /// step does not come back. A phone that already answered "don't allow"
  /// goes straight to Home, where the paused-detection chip explains.
  Future<void> _readyOrAskLocation() async {
    final store = ref.read(setupProgressStoreProvider);
    if (await store.locationStepSeen()) {
      await _finishSetup();
      return;
    }
    AppLocationPermissionResult result;
    try {
      result = await _permissions.checkStatus();
    } on Object {
      await _finishSetup();
      return;
    }
    if (!ref.mounted) return;
    await store.markLocationStepSeen();
    if (!ref.mounted) return;
    if (result != AppLocationPermissionResult.denied) {
      await _finishSetup();
      return;
    }
    state = state.copyWith(
      phase: StartupStep.permission,
      isDeviceLocationAsk: true,
      isLocationPermanentlyDenied: false,
      permissionError: () => null,
    );
  }

  /// The permission page's "Not now": Home. During setup that also puts the
  /// account in manual mode (turn location on in Settings); for a returning
  /// user on a new phone it changes nothing on the account, because another
  /// phone may still be using automatic detection.
  Future<void> skipLocation() async {
    if (state.isRequestingLocation) return;
    if (!state.isDeviceLocationAsk) {
      try {
        await ref.read(profileSettingsRepositoryProvider)?.update({
          'location_mode': 'manual',
        });
      } on Object {
        // A preference only; Home opens either way.
      }
      if (!ref.mounted) return;
    }
    await _finishSetup();
  }

  /// The permission page's button: the OS prompt, or OS settings if needed.
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
