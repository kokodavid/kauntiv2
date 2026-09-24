import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_photo_parts.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/map_place.dart';
import 'map_home_links.dart';

/// The sheet for a tapped place pin, in the feature-card style: the place
/// photo with its name, county and type, a Route button on the photo, the
/// summary, and "View place".
class RealMapPlaceSheet extends StatelessWidget {
  const RealMapPlaceSheet({
    super.key,
    required this.place,
    this.onOpen,
    this.onRoute,
  });

  final MapPlace place;

  /// Opens Place Detail after the sheet closes; null hides the button.
  final VoidCallback? onOpen;

  /// Driving directions to the pin; null hides Route.
  final AppOpenDirections? onRoute;

  /// Shows the sheet; [onOpenPlace] runs with [context] after it closes.
  static Future<void> show(
    BuildContext context,
    MapPlace place, {
    OpenPlaceDetail? onOpenPlace,
    AppOpenDirections? onRoute,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.foreground.withValues(alpha: 0.28),
      isScrollControlled: true,
      builder: (_) => RealMapPlaceSheet(
        place: place,
        onOpen: onOpenPlace == null
            ? null
            : () => onOpenPlace(context, place.id),
        onRoute: onRoute,
      ),
    );
  }

  /// One place's type, singular ("Park"), for the photo pill.
  static String typeLabel(String type) => switch (type) {
    'park' => 'Park',
    'museum' => 'Museum',
    'culture' => 'Culture',
    'heritage' => 'Heritage',
    'shore' => 'Shore',
    '' => 'Place',
    _ => '${type[0].toUpperCase()}${type.substring(1)}',
  };

  @override
  Widget build(BuildContext context) {
    final county = CountyPaths.byCode[place.countyCode];
    final summary = place.summary?.trim();
    final route = onRoute;
    final open = onOpen;
    return Container(
        width: double.infinity,
        // The white runs under the home indicator; only the content is inset.
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Handle(),
            if (county != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AppPhotoHeader(
                  county: county,
                  title: place.name,
                  caption: '${county.name} County',
                  imageUrl: place.thumbnailUrl,
                  height: 180,
                  topLeft: AppPhotoPill(label: typeLabel(place.type)),
                  bottomRight: route == null
                      ? null
                      : AppPhotoButton(
                          onPressed: () => openRoute(
                            context,
                            '${place.lat},${place.lng}',
                            route,
                          ),
                        ),
                ),
              )
            else
              Text(place.name, style: AppTypeScale.sectionTitle),
            if (summary != null && summary.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  summary,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.body,
                ),
              ),
            ],
            if (open != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    open();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentForeground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'View place',
                    style: AppTextStyles.buttonLabel,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.trackInactive,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
