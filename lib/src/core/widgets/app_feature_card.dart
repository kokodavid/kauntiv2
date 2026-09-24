import 'package:flutter/material.dart';

import '../../counties/county_paths.dart';
import '../../design/app_colors.dart';
import '../../widgets/app_county_shape.dart';
import '../design/app_type_scale.dart';
import 'app_photo_parts.dart';

/// The featured county / place card shared by Home's For You and
/// Explore's MINE / UNCLAIMED (Figma "Your next best move"): an inset
/// photo with a title, a pinned caption, an optional label and actions;
/// below it "`<County>` County", one line of context, stats and the county
/// shape in a white squircle.
class AppFeatureCard extends StatelessWidget {
  const AppFeatureCard({
    super.key,
    required this.county,
    required this.photoTitle,
    required this.photoCaption,
    required this.line,
    required this.stats,
    required this.onTap,
    this.photoUrl,
    this.label,
    this.actions = const [],
  });

  final CountyPath county;
  final String photoTitle;
  final String photoCaption;
  final String? photoUrl;

  /// Top-left label on the photo ("AD", "JUST UNLOCKED").
  final String? label;
  final String line;
  final List<({String value, String label})> stats;
  final VoidCallback onTap;

  /// Photo actions, bottom-right ([AppPhotoButton]s such as Route).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AppPhotoHeader(
                county: county,
                title: photoTitle,
                caption: photoCaption,
                imageUrl: photoUrl,
                height: 136,
                topLeft: label == null ? null : AppPhotoPill(label: label),
                titleRightInset: actions.length > 1 ? 180 : 104,
                bottomRight: actions.isEmpty
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final (i, action) in actions.indexed) ...[
                            if (i > 0) const SizedBox(width: 6),
                            action,
                          ],
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Details(card: this)),
                  const SizedBox(width: 12),
                  _CountyTile(county: county),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.card});

  final AppFeatureCard card;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${card.county.name} County',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypeScale.compactTitle,
        ),
        const SizedBox(height: 2),
        Text(
          card.line,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypeScale.small,
        ),
        if (card.stats.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.trackInactive),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (i, stat) in card.stats.indexed) ...[
                if (i > 0) const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeScale.compactStatValue,
                      ),
                      Text(stat.label, style: AppTypeScale.compactStatLabel),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// The county's shape in a white squircle (County Detail's treatment).
class _CountyTile extends StatelessWidget {
  const _CountyTile({required this.county});

  final CountyPath county;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.countyShapeCardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: AppCountyShape(county: county, fill: AppColors.accent),
    );
  }
}
