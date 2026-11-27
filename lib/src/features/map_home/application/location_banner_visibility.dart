import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether Home may still show the location banner in the stat card's place.
/// It starts visible and is switched off for the rest of the app launch once
/// the banner has had its few seconds, so the next cold start shows it again
/// while a problem remains. Held for the life of the app, not per screen,
/// so coming back to Home doesn't replay it.
final locationBannerVisibleProvider =
    NotifierProvider<LocationBannerVisibility, bool>(
      LocationBannerVisibility.new,
    );

class LocationBannerVisibility extends Notifier<bool> {
  /// How long the banner stays before the stat card comes back.
  static const showFor = Duration(seconds: 6);

  @override
  bool build() => true;

  void dismiss() => state = false;
}
