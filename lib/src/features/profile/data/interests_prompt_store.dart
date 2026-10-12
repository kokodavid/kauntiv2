import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, per account on this phone, how many times the app has been
/// opened to Home and whether the "Tell us what you like" card was
/// dismissed. Local only: it is a nudge, not account data.
abstract interface class InterestsPromptStore {
  /// Counts one more session for [owner] and returns the new total.
  Future<int> recordSession(String owner);

  Future<bool> isDismissed(String owner);
  Future<void> dismiss(String owner);
}

class SharedPreferencesInterestsPromptStore implements InterestsPromptStore {
  const SharedPreferencesInterestsPromptStore();

  static String _sessions(String owner) => 'interests_prompt.sessions.$owner';
  static String _dismissed(String owner) => 'interests_prompt.dismissed.$owner';

  @override
  Future<int> recordSession(String owner) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final next = (prefs.getInt(_sessions(owner)) ?? 0) + 1;
      await prefs.setInt(_sessions(owner), next);
      return next;
    } on Object {
      return 0;
    }
  }

  @override
  Future<bool> isDismissed(String owner) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_dismissed(owner)) ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> dismiss(String owner) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dismissed(owner), true);
    } on Object {
      // Worst case the card shows once more.
    }
  }
}
