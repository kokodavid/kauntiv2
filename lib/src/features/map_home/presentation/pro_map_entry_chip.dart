import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/map_home_models.dart';
import '../domain/map_place.dart';
import 'pro_map_screen.dart';

/// SPIKE: opens [ProMapScreen]. Shown only when a Mapbox token is
/// configured; a real build would gate this on the Pro entitlement and
/// send free users to the paywall instead.
class ProMapEntryChip extends StatelessWidget {
  const ProMapEntryChip({super.key, required this.data, this.loadPlaces});

  final MapHomeBoardData data;
  final Future<List<MapPlace>> Function()? loadPlaces;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mapOverlayBackground,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProMapScreen(
              accessToken: ProMapScreen.configuredAccessToken,
              badges: data.countyBadges,
              homeCountySlug: data.homeCounty?.slug,
              loadPlaces: loadPlaces,
            ),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.public,
                size: 12,
                color: AppColors.mapOverlayForeground,
              ),
              SizedBox(width: 5),
              Text('REAL MAP · PRO', style: AppTextStyles.mapOverlayChip),
            ],
          ),
        ),
      ),
    );
  }
}
