part of 'startup_flow.dart';

mixin _StartupPermissionSteps on _$StartupFlow {
  AppLocationPermissionService get _permissions;
  Future<void> _afterLocationGranted();

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
        await _afterLocationGranted();
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
    await _afterLocationGranted();
  }
}
