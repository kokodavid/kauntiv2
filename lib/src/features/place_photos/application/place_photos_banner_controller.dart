import '../data/place_photos_banner_store.dart';

/// Application boundary for Place Detail's local photo-nudge preference.
///
/// The presentation layer owns the transient loading and hidden states; this
/// controller keeps the SharedPreferences implementation behind the feature's
/// application layer.
class PlacePhotosBannerController {
  const PlacePhotosBannerController({
    PlacePhotosBannerStore store =
        const SharedPreferencesPlacePhotosBannerStore(),
  }) : _store = store;

  final PlacePhotosBannerStore _store;

  Future<bool> isDismissed(String owner) => _store.isDismissed(owner);

  Future<void> dismiss(String owner) => _store.dismiss(owner);
}

const placePhotosBannerController = PlacePhotosBannerController();
