import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/place_type.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_day.dart';
import 'plan_place_thumb.dart';
import 'plan_pro_sheet.dart';

typedef OpenPlanPlace = void Function(BuildContext context, String placeId);

/// "Waterfall · Nakuru".
String planPlaceMeta(String type, int countyCode) {
  final kind = type.isEmpty ? null : PlaceType.of(type).label;
  final county = CountyPaths.byCode[countyCode]?.name;
  return [?kind, ?county].join(' · ');
}

/// One stop on a day: its number in the day's colour, the place, a note,
/// who added it on a shared plan, and the road line down to the next stop.
class PlanStopRow extends StatelessWidget {
  const PlanStopRow({
    super.key,
    required this.stop,
    required this.number,
    required this.color,
    required this.isLast,
    this.locked = false,
    this.showAddedBy = false,
    this.onOpenPlace,
  });

  final PlanStop stop;
  final int number;
  final Color color;
  final bool isLast;

  /// Past the owner's stops-per-day limit (after a downgrade).
  final bool locked;
  final bool showAddedBy;
  final OpenPlanPlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final meta = planPlaceMeta(stop.place.type, stop.place.countyCode);
    final by = showAddedBy ? stop.addedByHandle : null;
    return Semantics(
      button: onOpenPlace != null,
      label: 'Stop $number, ${stop.place.name}',
      child: InkWell(
        onTap: onOpenPlace == null
            ? null
            : () => onOpenPlace!(context, stop.place.id),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: locked ? AppColors.mutedForeground : color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '$number',
                        style: AppTypeScale.meta.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 3,
                          margin: const EdgeInsets.only(top: 2),
                          color: color.withValues(alpha: 0.35),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.place.name,
                        style: AppTypeScale.itemTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (meta.isNotEmpty) Text(meta, style: AppTypeScale.meta),
                      if (stop.note != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            stop.note!,
                            style: AppTypeScale.small.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (by != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('Added by $by', style: AppTypeScale.meta),
                        ),
                      if (locked)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              PlanProTag(),
                              SizedBox(width: 6),
                              Text(
                                "Over this plan's limit",
                                style: AppTypeScale.meta,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 12),
                child: PlanPlaceThumb(url: stop.place.thumbnailUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
