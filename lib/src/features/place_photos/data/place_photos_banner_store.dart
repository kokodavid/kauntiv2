import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, per account on this phone, whether Place Detail's "add
/// your photos" nudge banner has been dismissed. Local only -- a nudge,
/// not account data -- same pattern as
/// `SharedPreferencesInterestsPromptStore` in the profile feature.
abstract interface class PlacePhotosBannerStore {
  Future<bool> isDismissed(String owner);
  Future<void> dismiss(String owner);
}

class SharedPreferencesPlacePhotosBannerStore
    implements PlacePhotosBannerStore {
  const SharedPreferencesPlacePhotosBannerStore();

  static String _dismissed(String owner) =>
      'place_photos_banner.dismissed.$owner';

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
      // Worst case the banner shows once more.
    }
  }
}
