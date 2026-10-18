import 'package:flutter/material.dart';

import '../../../core/widgets/app_photo_viewer.dart';
import '../domain/place_photo_item.dart';

/// Opens a place's [photos] in the app-wide viewer at [index], crediting
/// user photos along the bottom.
void openPlacePhotos(
  BuildContext context,
  List<PlacePhotoItem> photos,
  int index,
) => openAppPhotoViewer(context, [
  for (final photo in photos)
    AppViewerPhoto(
      id: photo.url,
      url: photo.url,
      caption: photo.isUser ? photo.creditLine : null,
    ),
], initialIndex: index);
