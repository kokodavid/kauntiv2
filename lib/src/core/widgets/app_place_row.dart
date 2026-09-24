import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../design/app_type_scale.dart';
import 'app_save_icon.dart';

/// The shared place row (v1 `AppPlaceRow`): a 54px thumbnail, the title
/// with an optional promotion tag, one line of description, a category
/// chip with an optional distance, and a save toggle. Used by Explore's
/// county cards and the arrival sheet, so a place looks the same
/// everywhere it's listed.
class AppPlaceRow extends StatelessWidget {
  const AppPlaceRow({
    super.key,
    required this.title,
    required this.description,
    required this.categoryLabel,
    required this.saved,
    this.thumbnailUrl,
    this.promotionLabel,
    this.distanceLabel,
    this.onTap,
    this.onSaveChanged,
  });

  final String title;
  final String description;
  final String categoryLabel;
  final bool saved;
  final String? thumbnailUrl;

  /// "AD" on promoted places; null hides the tag.
  final String? promotionLabel;
  final String? distanceLabel;
  final VoidCallback? onTap;

  /// Null hides the save toggle. Throwing reverts it with a note.
  final Future<void> Function(bool saved)? onSaveChanged;

  static const _title = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: AppTypeScale.itemTitleSize,
    fontWeight: FontWeight.w500,
    height: 21 / 14,
    color: AppColors.exploreText,
  );
  static const _body = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: AppTypeScale.smallSize,
    height: 18 / 12,
    color: AppColors.exploreMutedText,
  );
  static const _chip = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: AppTypeScale.labelSize,
    fontWeight: FontWeight.w500,
    letterSpacing: AppTypeScale.labelTracking,
    color: AppColors.exploreCategoryText,
  );
  static const _distance = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: AppTypeScale.metaSize,
    color: AppColors.exploreMutedText,
  );

  @override
  Widget build(BuildContext context) {
    final thumbnail = thumbnailUrl;
    final onSave = onSaveChanged;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox.square(
                dimension: 54,
                child: thumbnail == null
                    ? const ColoredBox(color: AppColors.explorePhotoPlaceholder)
                    : Image.network(
                        thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(
                              color: AppColors.explorePhotoPlaceholder,
                            ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _text()),
            if (onSave != null) AppSaveIcon(saved: saved, onChanged: onSave),
          ],
        ),
      ),
    );
  }

  Widget _text() {
    final promotion = promotionLabel;
    final distance = distanceLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _title,
              ),
            ),
            if (promotion != null) ...[
              const SizedBox(width: 6),
              _Chip(
                label: promotion,
                fill: AppColors.explorePromotionFill,
                style: _chip.copyWith(color: AppColors.explorePromotionText),
              ),
            ],
          ],
        ),
        Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _body,
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            _Chip(
              label: categoryLabel.toUpperCase(),
              fill: AppColors.exploreCategoryFill,
              style: _chip,
            ),
            if (distance != null) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '· $distance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _distance,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.fill, required this.style});

  final String label;
  final Color fill;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: style),
    );
  }
}
