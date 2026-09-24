import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

/// Pin colour and label per place type, shared by the map layer, the
/// legend and the place sheet.
abstract final class RealMapPlaceTypes {
  static const known = <String, (String, Color)>{
    'park': ('Parks', AppColors.placePark),
    'museum': ('Museums', AppColors.placeMuseum),
    'culture': ('Culture', AppColors.placeCulture),
    'heritage': ('Heritage', AppColors.placeHeritage),
    'shore': ('Shores', AppColors.placeShore),
  };

  static Color colorFor(String type) => known[type]?.$2 ?? AppColors.placeOther;

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
class RealMapPlaceLegend extends StatelessWidget {
  const RealMapPlaceLegend({super.key});

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
            for (final entry in RealMapPlaceTypes.known.values)
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
