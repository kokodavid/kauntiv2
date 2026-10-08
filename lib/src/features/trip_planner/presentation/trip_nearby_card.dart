import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/nearby_places.dart';

/// What a nearby place would do for the trip, as the card's last line.
enum TripNearbyNote {
  none('', AppColors.mutedForeground),
  onTrip('On your trip', AppColors.accent),
  newCounty('Adds a new county', AppColors.newCountyText),
  alreadyOnWay('County already on your way', AppColors.mutedForeground);

  const TripNearbyNote(this.label, this.color);

  final String label;
  final Color color;
}

/// One "Add a stop" card: photo with a round + / check toggle, name,
/// distance and county, and what it adds. Tap toggles the stop; a long
/// press offers "View place".
class TripNearbyCard extends StatelessWidget {
  const TripNearbyCard({
    super.key,
    required this.entry,
    required this.added,
    required this.disabled,
    required this.note,
    required this.onToggle,
    this.onView,
  });

  final NearbyPlace entry;
  final bool added;

  /// The trip is full and this place is not on it: dimmed, no response.
  final bool disabled;
  final TripNearbyNote note;
  final VoidCallback onToggle;
  final VoidCallback? onView;

  static const width = 140.0;

  Future<void> _menu(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset(box.size.width / 2, 60));
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final picked = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromRect(
        origin & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: const [PopupMenuItem(value: true, child: Text('View place'))],
    );
    if (picked ?? false) onView?.call();
  }

  @override
  Widget build(BuildContext context) {
    final place = entry.place;
    final county = CountyPaths.byCode[place.countyCode]?.name ?? '';
    final url = place.thumbnailUrl;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Semantics(
        button: true,
        selected: added,
        enabled: !disabled,
        label: '${added ? 'Remove' : 'Add'} ${place.name} as a stop',
        child: InkWell(
          onTap: disabled ? null : onToggle,
          onLongPress: onView == null || disabled ? null : () => _menu(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: added ? AppColors.accent : AppColors.cardBorder,
                width: added ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (url == null)
                        const ColoredBox(color: AppColors.lockedFill)
                      else
                        Image(
                          image: appNetworkImage(url),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(color: AppColors.lockedFill),
                        ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: added ? AppColors.accent : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            added ? Icons.check : Icons.add,
                            size: 18,
                            color: added ? Colors.white : AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeScale.itemTitle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${entry.distanceLabel} · $county',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeScale.small,
                      ),
                      Text(
                        note.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeScale.small.copyWith(
                          color: note.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
