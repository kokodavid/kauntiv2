import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/trip_plan.dart';
import 'plan_place_thumb.dart';
import 'plan_stop_row.dart';

/// "Places to visit" (design 3a): places picked for the plan but not on a
/// day yet. Folded to one row; opens to the list.
class PlanPlacesRow extends StatefulWidget {
  const PlanPlacesRow({
    super.key,
    required this.ideas,
    required this.maxPlaces,
    this.onOpenPlace,
    this.onAdd,
  });

  final List<PlanIdea> ideas;
  final int maxPlaces;
  final OpenPlanPlace? onOpenPlace;

  /// Opens Add places for the list (people who can edit).
  final VoidCallback? onAdd;

  @override
  State<PlanPlacesRow> createState() => _PlanPlacesRowState();
}

class _PlanPlacesRowState extends State<PlanPlacesRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.ideas.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.exploreSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.exploreBorder),
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: count == 0 ? null : () => setState(() => _open = !_open),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_border, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Places to visit',
                              style: AppTypeScale.itemTitle,
                            ),
                            Text(
                              count == 0
                                  ? 'Nothing saved for this plan yet.'
                                  : '$count of ${widget.maxPlaces} · not on a day yet',
                              style: AppTypeScale.meta,
                            ),
                          ],
                        ),
                      ),
                      if (count > 0)
                        Icon(_open ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_open)
            for (final idea in widget.ideas)
              InkWell(
                onTap: widget.onOpenPlace == null
                    ? null
                    : () => widget.onOpenPlace!(context, idea.place.id),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      PlanPlaceThumb(url: idea.place.thumbnailUrl, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              idea.place.name,
                              style: AppTypeScale.itemTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              planPlaceMeta(
                                idea.place.type,
                                idea.place.countyCode,
                              ),
                              style: AppTypeScale.meta,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (widget.onAdd != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add places'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
