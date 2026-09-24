import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/county_detail.dart';
import 'detail_widgets.dart';

/// Full-photo place card on County Detail's "Places to See" list (v1's
/// `AppPlacePhotoCard`): photo with a save toggle, then category, title
/// and a two-line summary.
class PlacePhotoCard extends StatelessWidget {
  const PlacePhotoCard({
    super.key,
    required this.place,
    required this.onTap,
    required this.onSavedChanged,
  });

  final CountyDetailPlace place;
  final VoidCallback onTap;
  final Future<void> Function(bool saved) onSavedChanged;

  @override
  Widget build(BuildContext context) {
    final photoUrl = place.thumbnailUrl;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.factCardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                  bottom: Radius.circular(5),
                ),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photoUrl == null)
                        const ColoredBox(color: AppColors.lockedFill)
                      else
                        Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(color: AppColors.lockedFill),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: DetailSaveButton(
                          saved: place.saved,
                          size: 32,
                          unsavedColor: Colors.white,
                          onChanged: onSavedChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.category.label,
                      style: AppTextStyles.detailStatLabel,
                    ),
                    Text(
                      place.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.placeCardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.listItemSubtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
