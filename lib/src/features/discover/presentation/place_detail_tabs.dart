import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

enum PlaceDetailTab { about, plan }

/// The About / Plan trip switch under the header: a pale track with a white
/// pill on the chosen side.
class PlaceDetailTabs extends StatelessWidget {
  const PlaceDetailTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PlaceDetailTab selected;
  final ValueChanged<PlaceDetailTab> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.segmentedTrack,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      spacing: 3,
      children: [
        for (final (tab, label) in const [
          (PlaceDetailTab.about, 'About'),
          (PlaceDetailTab.plan, 'Plan trip'),
        ])
          Expanded(
            child: Semantics(
              button: true,
              selected: selected == tab,
              child: GestureDetector(
                onTap: () => onChanged(tab),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == tab ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: selected == tab
                        ? const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTypeScale.family,
                      fontSize: 14,
                      fontWeight: selected == tab
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: selected == tab
                          ? AppColors.foreground
                          : AppColors.offlineBody,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// The soft card at the end of About that leads to the planner.
class PlaceDetailPlanNudge extends StatelessWidget {
  const PlaceDetailPlanNudge({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan a trip here',
                  style: TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'See the road and add stops',
                  style: TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 12,
                    color: AppColors.noteMutedText,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: AppColors.accent,
            ),
            child: const Text('Plan trip'),
          ),
        ],
      ),
    ),
  );
}
