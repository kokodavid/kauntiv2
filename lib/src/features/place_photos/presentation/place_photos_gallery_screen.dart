import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../design/app_colors.dart';
import '../domain/place_photo_item.dart';
import 'place_photo_add_tile.dart';
import 'place_photo_tile.dart';
import 'place_photo_viewer.dart';

/// "See all": every photo of the place in two columns, each with its
/// credit underneath. Add photo comes first when the place takes photos.
class PlacePhotosGalleryScreen extends StatelessWidget {
  const PlacePhotosGalleryScreen({
    super.key,
    required this.placeName,
    required this.photos,
    this.onAdd,
    this.offline = false,
  });

  final String placeName;
  final List<PlacePhotoItem> photos;

  /// Null when the place can't take photos (no add tile).
  final VoidCallback? onAdd;
  final bool offline;

  static const _gap = 12.0;
  static const _captionHeight = 20.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  AppBackButton(
                    size: 44,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Photos', style: AppTypeScale.sectionTitle),
                        Text(
                          '$placeName · ${photos.length}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTypeScale.family,
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final side = (box.maxWidth - 32 - 10) / 2;
                  // Masonry: every photo keeps its own shape (BoxFit.cover
                  // only trims extreme ones) and the next one goes into
                  // whichever column is shorter, so the two stay level.
                  final columns = <List<Widget>>[[], []];
                  final used = <double>[0, 0];
                  void place(double height, Widget child) {
                    final col = used[1] < used[0] ? 1 : 0;
                    columns[col].add(child);
                    used[col] += height + _gap;
                  }

                  if (onAdd != null) {
                    final h = side * 0.9;
                    place(
                      h + _captionHeight,
                      Padding(
                        padding: const EdgeInsets.only(bottom: _gap),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlacePhotoAddTile(
                              onPressed: onAdd!,
                              offline: offline,
                              width: side,
                              height: h,
                            ),
                            const SizedBox(height: 6),
                            const _Caption('Been here?'),
                          ],
                        ),
                      ),
                    );
                  }
                  for (var i = 0; i < photos.length; i++) {
                    final photo = photos[i];
                    final ratio = (photo.aspect ?? 0.8).clamp(0.66, 1.5);
                    final h = side / ratio;
                    place(
                      h + _captionHeight,
                      Padding(
                        padding: const EdgeInsets.only(bottom: _gap),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlacePhotoTile(
                              photo: photo,
                              size: side,
                              height: h,
                              showCredit: false,
                              onTap: () => openPlacePhotos(context, photos, i),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: side,
                              child: _Caption(photo.creditLine),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(children: columns[0]),
                        const SizedBox(width: 10),
                        Column(children: columns[1]),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontFamily: AppTypeScale.family,
      fontSize: 12,
      color: AppColors.mutedForeground,
    ),
  );
}
