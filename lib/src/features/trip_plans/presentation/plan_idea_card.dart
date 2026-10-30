import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/place_type.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_member.dart';
import '../domain/trip_plan.dart';
import 'plan_avatar_stack.dart';
import 'plan_place_thumb.dart';
import 'plan_stop_row.dart';

/// One place in Places to visit (design 3a): photo, who added it, its type
/// and county, the note, and "Add to Day…" for people who can edit.
class PlanIdeaCard extends StatelessWidget {
  const PlanIdeaCard({
    super.key,
    required this.idea,
    this.adder,
    this.onOpen,
    this.onAddToDay,
  });

  final PlanIdea idea;

  /// Who added it, on a shared plan.
  final PlanMember? adder;
  final OpenPlanPlace? onOpen;
  final VoidCallback? onAddToDay;

  @override
  Widget build(BuildContext context) {
    final place = idea.place;
    final kind = place.type.isEmpty ? null : PlaceType.of(place.type).label;
    final county = CountyPaths.byCode[place.countyCode]?.name;
    return SizedBox(
      width: 252,
      child: Material(
        color: AppColors.exploreSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.exploreBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpen == null ? null : () => onOpen!(context, place.id),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PlanPlaceThumb(url: place.thumbnailUrl, size: 48),
                        if (adder != null)
                          Positioned(
                            right: -8,
                            bottom: -8,
                            child: PlanAvatarStack(
                              members: [adder!],
                              size: 22,
                              max: 1,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: AppTypeScale.itemTitle.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (kind != null) _TypeChip(kind),
                              if (kind != null && county != null)
                                const SizedBox(width: 6),
                              if (county != null)
                                Flexible(
                                  child: Text(
                                    county,
                                    style: AppTypeScale.small,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (idea.note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      idea.note!,
                      style: AppTypeScale.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (adder != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Added by ${adder!.handle}',
                      style: AppTypeScale.meta,
                    ),
                  ),
                if (onAddToDay != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        backgroundColor: AppColors.accentTint,
                        textStyle: AppTypeScale.action,
                        minimumSize: const Size.fromHeight(40),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: onAddToDay,
                      child: const Text('Add to Day…'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip(this.label);

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
