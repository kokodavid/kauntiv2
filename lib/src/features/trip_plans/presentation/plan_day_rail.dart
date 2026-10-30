import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_labels.dart';
import '../domain/plan_route.dart';

const _railWidth = 44.0;

/// "Start · Westlands, Nairobi" (design 3a): a hollow marker on the rail.
class PlanEndpointRow extends StatelessWidget {
  const PlanEndpointRow({
    super.key,
    required this.label,
    this.stay = false,
    this.last = false,
    this.top = 8,
  });

  final String label;

  /// Tonight's stay: a moon instead of the start ring.
  final bool stay;
  final bool last;

  /// Space above; none when it is the first thing under the day header.
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(12, top, 16, last ? 10 : 2),
    child: Row(
      children: [
        SizedBox(
          width: _railWidth - 12,
          child: Center(
            child: stay
                ? const Icon(
                    Icons.dark_mode_outlined,
                    size: 18,
                    color: AppColors.mutedForeground,
                  )
                : Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.foreground, width: 2.5),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTypeScale.small)),
      ],
    ),
  );
}

/// "about 50 min · 41 km" between two stops, on the rail.
class PlanLegRow extends StatelessWidget {
  const PlanLegRow({super.key, required this.leg});

  final PlanLeg leg;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 12, right: 16),
    child: IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: _railWidth - 12,
            child: Center(
              child: Container(
                width: 3,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.exploreBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.directions_car_outlined,
            size: 14,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(width: 8),
          Text(
            '${PlanLabels.drive(leg.durationS)} · '
            '${PlanLabels.distance(leg.distanceM)}',
            style: AppTypeScale.meta,
          ),
        ],
      ),
    ),
  );
}
