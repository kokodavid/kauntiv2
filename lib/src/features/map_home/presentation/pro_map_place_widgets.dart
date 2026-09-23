import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/map_place.dart';

/// Pin colour and label per place type, shared by the map layer, the
/// legend and the place sheet.
abstract final class ProMapPlaceTypes {
  static const known = <String, (String, Color)>{
    'park': ('Parks', AppColors.placePark),
    'museum': ('Museums', AppColors.placeMuseum),
    'culture': ('Culture', AppColors.placeCulture),
    'heritage': ('Heritage', AppColors.placeHeritage),
    'shore': ('Shores', AppColors.placeShore),
  };

  static Color colorFor(String type) =>
      known[type]?.$2 ?? AppColors.placeOther;

  static IconData iconFor(String type) => switch (type) {
    'park' => Icons.forest,
    'museum' => Icons.museum,
    'culture' => Icons.theater_comedy,
    'heritage' => Icons.account_balance,
    'shore' => Icons.beach_access,
    _ => Icons.place,
  };
}

/// Compact legend for the place pins.
class ProMapPlaceLegend extends StatelessWidget {
  const ProMapPlaceLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in ProMapPlaceTypes.known.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Dot(color: entry.$2),
                    const SizedBox(width: 6),
                    Text(entry.$1, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for a tapped place pin.
class ProMapPlaceSheet extends StatelessWidget {
  const ProMapPlaceSheet({super.key, required this.place});

  final MapPlace place;

  @override
  Widget build(BuildContext context) {
    final county = CountyPaths.byCode[place.countyCode];
    final typeLabel = ProMapPlaceTypes.known[place.type]?.$1 ?? place.type;
    final summary = place.summary;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.trackInactive,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            if (place.thumbnailUrl case final url?) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                _Dot(color: ProMapPlaceTypes.colorFor(place.type)),
                const SizedBox(width: 6),
                Text(
                  [typeLabel, if (county != null) county.name]
                      .join(' · ')
                      .toUpperCase(),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(place.name, style: AppTextStyles.heading),
            if (summary != null && summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(summary, style: AppTextStyles.bodyMuted),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
