import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/place_type.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/plan_counties.dart';
import '../domain/plan_day.dart';
import '../domain/plan_labels.dart';
import 'plan_place_thumb.dart';
import 'plan_pro_sheet.dart';

typedef OpenPlanPlace = void Function(BuildContext context, String placeId);

/// "Waterfall · Nakuru".
String planPlaceMeta(String type, int countyCode) {
  final kind = type.isEmpty ? null : PlaceType.of(type).label;
  final county = CountyPaths.byCode[countyCode]?.name;
  return [?kind, ?county].join(' · ');
}

/// One stop on a day (design 3a): its number in the day's colour, the
/// photo, the place with its type and county, a note, who added it on a
/// shared plan, and the "…" for people who can edit.
class PlanStopRow extends ConsumerWidget {
  const PlanStopRow({
    super.key,
    required this.stop,
    required this.number,
    required this.color,
    this.countyStatus,
    this.locked = false,
    this.showAddedBy = false,
    this.onOpenPlace,
    this.menu,
  });

  final PlanStop stop;
  final int number;
  final Color color;

  /// How the stop's county stands for me: home, claimed, or new.
  final PlanCountyStatus? countyStatus;

  /// Past the owner's stops-per-day limit (after a downgrade).
  final bool locked;
  final bool showAddedBy;
  final OpenPlanPlace? onOpenPlace;

  /// The "…" for people who can edit.
  final Widget? menu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = stop.place;
    final kind = place.type.isEmpty ? null : PlaceType.of(place.type).label;
    final county = CountyPaths.byCode[place.countyCode]?.name;
    final by = showAddedBy ? stop.addedByHandle : null;
    final now = DateTime.now();
    final ago = by == null ? null : PlanLabels.ago(stop.updatedAt, now);
    // Someone else's change from the last few minutes stands out softly.
    final fresh =
        by != null &&
        stop.addedBy != ref.watch(currentUserIdProvider)() &&
        PlanLabels.isFresh(stop.updatedAt, now);
    return Semantics(
      button: onOpenPlace != null,
      label: 'Stop $number, ${place.name}',
      child: InkWell(
        onTap: onOpenPlace == null ? null : () => onOpenPlace!(context, place.id),
        child: ColoredBox(
          color: fresh ? AppColors.accentTint : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(top: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: locked ? AppColors.mutedForeground : color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: AppTypeScale.action.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: PlanPlaceThumb(url: place.thumbnailUrl, size: 56),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: AppTypeScale.cardTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (kind != null) PlanTypeChip(kind),
                            if (county != null)
                              _County(county, countyStatus),
                          ],
                        ),
                        if (stop.note != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(stop.note!, style: AppTypeScale.body),
                          ),
                        if (by != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              ago == null ? 'Added by $by' : 'Added by $by · $ago',
                              style: AppTypeScale.meta,
                            ),
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
                if (menu != null)
                  Padding(padding: const EdgeInsets.only(top: 4), child: menu)
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The place type as a soft green chip ("Park", "Viewpoint").
class PlanTypeChip extends StatelessWidget {
  const PlanTypeChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.successTint,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: AppTypeScale.meta.copyWith(color: AppColors.green),
    ),
  );
}

/// The county with a dot for how it stands for me (home, claimed, new).
class PlanCountyDot extends StatelessWidget {
  const PlanCountyDot(this.status, {super.key});

  final PlanCountyStatus? status;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: switch (status) {
        PlanCountyStatus.home => AppColors.legendHome,
        PlanCountyStatus.claimed => AppColors.accent,
        _ => AppColors.faintForeground,
      },
      shape: BoxShape.circle,
    ),
  );
}

class _County extends StatelessWidget {
  const _County(this.name, this.status);

  final String name;
  final PlanCountyStatus? status;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      PlanCountyDot(status),
      const SizedBox(width: 5),
      Text(name, style: AppTypeScale.small),
      if (status == PlanCountyStatus.notClaimed) ...[
        const SizedBox(width: 5),
        Text(
          'New',
          style: AppTypeScale.small.copyWith(
            color: AppColors.newCountyText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ],
  );
}
