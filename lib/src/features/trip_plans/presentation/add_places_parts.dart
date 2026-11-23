import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../domain/plan_place.dart';
import 'plan_place_thumb.dart';
import 'plan_stop_row.dart';

class AddPlacesRow extends StatelessWidget {
  const AddPlacesRow({
    super.key,
    required this.place,
    required this.added,
    required this.adding,
    required this.pickOnly,
    required this.onTap,
  });

  final PlanPlace place;
  final bool added;
  final bool adding;
  final bool pickOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: added ? '${place.name}, added' : 'Add ${place.name}',
    child: InkWell(
      onTap: added ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          children: [
            PlanPlaceThumb(
              url: place.thumbnailUrl,
              size: 48,
              custom: place.isCustom,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: AppTypeScale.itemTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    place.isCustom && place.address != null
                        ? place.address!
                        : planPlaceMeta(
                            place.type,
                            place.countyCode,
                            custom: place.isCustom,
                          ),
                    style: AppTypeScale.meta,
                  ),
                ],
              ),
            ),
            if (!pickOnly)
              SizedBox(
                width: 44,
                height: 44,
                child: adding
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: AppProgressIndicator(radius: 8),
                      )
                    : Icon(
                        added ? Icons.check_circle : Icons.add_circle_outline,
                        color: added ? AppColors.legendHome : AppColors.accent,
                      ),
              ),
          ],
        ),
      ),
    ),
  );
}

class AddPlacesNote extends StatelessWidget {
  const AddPlacesNote(this.text, {super.key, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center, style: AppTypeScale.small),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
