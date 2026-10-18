import 'package:shared_preferences/shared_preferences.dart';

/// Whether this phone is part-way through new-user setup for an account.
///
/// Set when setup starts (no home county yet) and cleared when the user
/// reaches Home. It is what separates a new user who closed the app after
/// step 1 (resume setup) from a returning user who simply has no
/// interests saved (straight to Home). Lives on the phone only; a fresh
/// install with a saved home county is a returning user.
abstract interface class SetupProgressStore {
  Future<bool> isInProgress(String owner);
  Future<void> setInProgress(String owner, bool value);

  /// Whether this phone has already shown (or never needed) the location
  /// permission step. Permission belongs to the phone, not the account, so
  /// this is not keyed by user: a returning user signing in on a new phone,
  /// or after a reinstall, is asked once; a "Not now" is remembered.
  Future<bool> locationStepSeen();
  Future<void> markLocationStepSeen();
}

class SharedPreferencesSetupProgressStore implements SetupProgressStore {
  const SharedPreferencesSetupProgressStore();

  static String _key(String owner) => 'onboarding.setup_in_progress.$owner';
  static const _locationSeenKey = 'onboarding.location_step_seen';

  @override
  Future<bool> isInProgress(String owner) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key(owner)) ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> setInProgress(String owner, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool(_key(owner), true);
      } else {
        await prefs.remove(_key(owner));
      }
    } on Object {
      // Losing the flag only means setup restarts at the right step anyway.
    }
  }

  @override
  Future<bool> locationStepSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_locationSeenKey) ?? false;
    } on Object {
      // Unknown: treat as seen, so a storage problem never loops the step.
      return true;
    }
  }

  @override
  Future<void> markLocationStepSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationSeenKey, true);
    } on Object {
      // Worst case the step shows once more.
    }
  }
}
