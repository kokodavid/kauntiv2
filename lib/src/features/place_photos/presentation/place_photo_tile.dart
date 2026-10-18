import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../design/app_colors.dart';
import '../domain/place_photo_item.dart';

/// A photo in the strip: rounded, with "Photo by @username" over the
/// bottom when a user took it.
class PlacePhotoTile extends StatelessWidget {
  const PlacePhotoTile({
    super.key,
    required this.photo,
    this.size = 120,
    this.height,
    this.showCredit = true,
    this.onTap,
  });

  final PlacePhotoItem photo;
  final double size;

  /// Defaults to [size] (square); the gallery's staggered columns set it.
  final double? height;

  /// Draws the credit over the photo (the gallery puts it underneath).
  final bool showCredit;

  /// Opens the photo full screen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        height: height ?? size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.photoTileFill),
            Image(
              image: appNetworkImage(photo.url, cacheWidth: 400),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            if (photo.isUser && showCredit)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xB3000000)],
                    ),
                  ),
                  child: Text(
                    photo.creditLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTypeScale.family,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
