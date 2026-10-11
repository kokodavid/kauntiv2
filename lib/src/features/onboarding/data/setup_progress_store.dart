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
}

class SharedPreferencesSetupProgressStore implements SetupProgressStore {
  const SharedPreferencesSetupProgressStore();

  static String _key(String owner) => 'onboarding.setup_in_progress.$owner';

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
}
