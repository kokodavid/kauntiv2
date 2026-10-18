import 'package:flutter/material.dart';

import '../../../core/widgets/app_photo_viewer.dart';
import '../domain/journey_media_capture.dart';

AppViewerPhoto _asViewerPhoto(JourneyMediaItem item) =>
    AppViewerPhoto(id: item.id, url: item.url);

/// Opens [item] full screen over a black backdrop - shared by every
/// photo moment in the replay timeline. [onDelete], when given, shows a
/// delete button that hands this photo's removal off to the caller.
void openJourneyPhoto(
  BuildContext context,
  JourneyMediaItem item, {
  Future<bool> Function(BuildContext context, JourneyMediaItem item)? onDelete,
}) => openJourneyPhotos(context, [item], onDelete: onDelete);

/// Opens [items] in the app-wide swipeable photo viewer.
void openJourneyPhotos(
  BuildContext context,
  List<JourneyMediaItem> items, {
  int initialIndex = 0,
  Future<bool> Function(BuildContext context, JourneyMediaItem item)? onDelete,
}) => openAppPhotoViewer(
  context,
  [for (final item in items) _asViewerPhoto(item)],
  initialIndex: initialIndex,
  onDelete: onDelete == null
      ? null
      : (context, photo) => onDelete(
          context,
          items.firstWhere((item) => item.id == photo.id),
        ),
);
