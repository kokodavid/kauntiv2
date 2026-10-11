import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/map_place.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/saved_trip.dart';

/// One saved plan as a row: the destination's photo, the plan's name, and
/// where it goes and how many stops it has. Tap opens the plan; [menu]
/// (the saved plans screen) adds rename and delete.
class SavedPlanTile extends StatelessWidget {
  const SavedPlanTile({
    super.key,
    required this.plan,
    required this.destination,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  final SavedTrip plan;

  /// Null when the destination is no longer in the catalog.
  final MapPlace? destination;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  static const height = 68.0;

  String get _subtitle {
    final stops = plan.stopPlaceIds.length;
    final county = CountyPaths.byCode[destination?.countyCode]?.name;
    return [
      ?county,
      stops == 0 ? 'Direct' : '$stops ${stops == 1 ? 'stop' : 'stops'}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final url = destination?.thumbnailUrl;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: 48,
                  child: url == null
                      ? const ColoredBox(color: AppColors.lockedFill)
                      : Image(
                          image: appNetworkImage(url),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(color: AppColors.lockedFill),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypeScale.itemTitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypeScale.small,
                    ),
                  ],
                ),
              ),
              if (onRename != null && onDelete != null)
                PopupMenuButton<VoidCallback>(
                  tooltip: 'Plan options',
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppColors.mutedForeground,
                  ),
                  onSelected: (action) => action(),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: onRename, child: const Text('Rename')),
                    PopupMenuItem(value: onDelete, child: const Text('Delete')),
                  ],
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
