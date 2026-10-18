import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/discover/domain/place_detail.dart';
import '../features/place_photos/domain/place_photo_item.dart';
import '../features/place_photos/presentation/my_photos_profile_entry.dart';
import '../features/place_photos/presentation/my_photos_screen.dart';
import '../features/place_photos/presentation/place_photos_section.dart';
import '../features/profile/presentation/profile_tiles.dart';
import 'app_routes.dart';

/// Where user place photos meet the rest of the app. Features don't import
/// each other, so Place Detail's Photos section, Profile's "My photos" row
/// and the My photos screen are put together here.
abstract final class PlacePhotosRoutes {
  /// Place Detail's Photos section (About tab).
  static Widget placeSection(BuildContext context, PlaceDetailData place) {
    return PlacePhotosSection(
      placeId: place.id,
      placeName: place.title,
      canAdd: place.acceptsPhotos,
      photos: [
        for (var i = 0; i < place.images.length; i++)
          PlacePhotoItem(
            url: place.images[i],
            credit: i < place.imageCredits.length ? place.imageCredits[i] : null,
            aspect: i < place.imageAspects.length ? place.imageAspects[i] : null,
          ),
      ],
      onOpenMyPhotos: () => context.push(AppRoutes.myPhotos),
      onChooseUsername: () => context.go(AppRoutes.profile),
    );
  }

  /// Profile's "My photos" row (nothing while the feature is off).
  static Widget profileEntry(BuildContext context) => MyPhotosProfileEntry(
    builder: (context, subtitle, unseen) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ProfileTile(
        icon: Icons.photo_library_outlined,
        title: 'My photos',
        subtitle: subtitle,
        style: ProfileTileStyle.surface,
        showDot: unseen,
        onTap: () => context.push(AppRoutes.myPhotos),
      ),
    ),
  );

  static Widget myPhotos(BuildContext context) => MyPhotosScreen(
    onOpenPlace: (placeId) => context.push(AppRoutes.place(placeId)),
  );
}
