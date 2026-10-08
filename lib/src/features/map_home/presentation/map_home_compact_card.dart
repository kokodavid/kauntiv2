import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_county_shape.dart';
import 'map_home_primary_button.dart';

/// The collapsed sheet: one target, one 50 pt button. Fixed height so the sheet can size its
/// collapsed state without measuring.
class MapHomeCompactCard extends StatelessWidget {
  const MapHomeCompactCard({
    super.key,
    required this.kicker,
    required this.title,
    required this.meta,
    required this.county,
    required this.buttonLabel,
    required this.onPressed,
    this.imageUrl,
    this.onOpen,
  });

  /// The small caps line above the title.
  final String kicker;
  final String title;
  final String meta;
  final CountyPath county;
  final String? imageUrl;
  final String buttonLabel;
  final VoidCallback onPressed;
  final VoidCallback? onOpen;

  static const height = 130.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                _Thumb(county: county, imageUrl: imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kicker,
                        style: AppTypeScale.sectionLabel.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeScale.cardTitle,
                      ),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeScale.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MapHomePrimaryButton(label: buttonLabel, onPressed: onPressed),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.county, required this.imageUrl});

  final CountyPath county;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 68,
        height: 68,
        child: url == null
            ? _Fallback(county: county)
            : Image(
                image: appNetworkImage(url),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _Fallback(county: county),
              ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.county});

  final CountyPath county;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.lockedFill,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: AppCountyShape(
          county: county,
          fill: Colors.transparent,
          stroke: AppColors.lockedStroke,
          strokeWidth: 2,
          dashed: true,
        ),
      ),
    );
  }
}
