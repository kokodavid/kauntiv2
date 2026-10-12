part of 'startup_flow.dart';

/// The end of setup step 3: once location is granted, offer county-arrival
/// notifications, so the very first background crossing can notify. Split
/// out of [StartupFlow] to keep that file under the 300-line limit.
mixin _StartupNotificationSteps on _$StartupFlow {
  /// Setup is over: clear the flag and open Home.
  Future<void> _finishSetup();

  /// Location is granted (just now, or earlier): the notifications step,
  /// unless the phone already allows them (or has no prompt to show).
  Future<void> _afterLocationGranted() async {
    var allowed = false;
    try {
      allowed = await ref.read(arrivalNotifierProvider).isPermitted();
    } on Object {
      allowed = false;
    }
    if (!ref.mounted) return;
    if (allowed) {
      await _finishSetup();
      return;
    }
    state = state.copyWith(
      phase: StartupStep.notifications,
      isLocationPermanentlyDenied: false,
      permissionError: () => null,
    );
  }

  /// "Turn on notifications": the OS prompt, then Home whatever the answer
  /// (a "no" can be changed later in Settings).
  Future<void> enableNotifications() async {
    if (state.isRequestingNotifications) return;
    state = state.copyWith(isRequestingNotifications: true);
    try {
      await ref.read(arrivalNotifierProvider).requestPermission();
    } on Object {
      // Home opens either way.
    }
    if (!ref.mounted) return;
    state = state.copyWith(isRequestingNotifications: false);
    await _finishSetup();
  }

  /// "Not now": Home, without using up the one-time OS prompt.
  Future<void> skipNotifications() async {
    if (state.isRequestingNotifications) return;
    await _finishSetup();
  }

  /// Back from the OS settings: carry on if permission was granted there.
  Future<void> recheckPermission() async {
    if (!state.isLocationPermanentlyDenied) return;
    final result = await ref
        .read(locationPermissionServiceProvider)
        .checkStatus();
    if (!ref.mounted || result != AppLocationPermissionResult.granted) return;
    await _afterLocationGranted();
  }
}
