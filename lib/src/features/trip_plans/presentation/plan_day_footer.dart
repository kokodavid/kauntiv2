import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_counties.dart';
import 'plan_day_parts.dart';
import 'plan_pro_sheet.dart';
import 'plan_stop_row.dart';

/// "PASSES THROUGH" with a pill per county (design 3a): a dot for how the
/// county stands for me, and "home" or "new" after the name.
class PlanPassesThrough extends StatelessWidget {
  const PlanPassesThrough({super.key, required this.counties});

  final List<PlanCounty> counties;

  @override
  Widget build(BuildContext context) {
    if (counties.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('PASSES THROUGH', style: AppTypeScale.sectionLabel),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in counties)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.exploreSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.exploreBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlanCountyDot(c.status),
                      const SizedBox(width: 6),
                      Text(
                        CountyPaths.byCode[c.code]?.name ?? '',
                        style: AppTypeScale.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.foreground,
                        ),
                      ),
                      if (c.status != PlanCountyStatus.claimed) ...[
                        const SizedBox(width: 6),
                        Text(
                          c.isNew ? 'new' : 'home',
                          style: AppTypeScale.small.copyWith(
                            color: c.isNew
                                ? AppColors.newCountyText
                                : AppColors.mutedForeground,
                            fontWeight: c.isNew ? FontWeight.w600 : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "+ Add stop", "From Places to visit", "Best order PRO": blue links for
/// people who can edit.
class PlanDayLinks extends StatelessWidget {
  const PlanDayLinks({super.key, required this.actions});

  final PlanDayActions actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
    child: Wrap(
      children: [
        _Link('+ Add stop', actions.onAddPlaces),
        if (actions.onAddFromPlaces != null)
          _Link('From Places to visit', actions.onAddFromPlaces!),
        if (actions.onChangeStart != null)
          _Link('Change start', actions.onChangeStart!),
        _Link(
          actions.hasOvernight ? 'Change stay' : 'Add overnight stay',
          actions.onOvernight,
        ),
        if (actions.onBestOrder != null)
          _Link(
            'Best order',
            actions.onBestOrder!,
            trailing: actions.bestOrderIsPro ? const PlanProTag() : null,
          ),
      ],
    ),
  );
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onPressed, {this.trailing});

  final String label;
  final VoidCallback onPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.accent,
      textStyle: AppTypeScale.action,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    ),
  );
}

/// "Start trip" and "Directions" side by side (design 3a).
class PlanDayButtons extends StatelessWidget {
  const PlanDayButtons({
    super.key,
    this.startLabel,
    this.onStart,
    this.onDirections,
  });

  final String? startLabel;
  final VoidCallback? onStart;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    if (onStart == null && onDirections == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        children: [
          if (onStart != null)
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentForeground,
                  textStyle: AppTypeScale.action.copyWith(fontWeight: FontWeight.w600),
                  minimumSize: const Size.fromHeight(40),
                  shape: const StadiumBorder(),
                ),
                onPressed: onStart,
                icon: const Icon(Icons.circle, size: 8),
                label: Text(startLabel ?? 'Start trip'),
              ),
            ),
          if (onStart != null && onDirections != null)
            const SizedBox(width: 12),
          if (onDirections != null)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.foreground,
                  textStyle: AppTypeScale.action.copyWith(fontWeight: FontWeight.w600),
                  side: const BorderSide(color: AppColors.exploreBorder),
                  minimumSize: const Size.fromHeight(40),
                  shape: const StadiumBorder(),
                ),
                onPressed: onDirections,
                icon: const Icon(Icons.navigation_outlined, size: 16),
                label: const Text('Directions'),
              ),
            ),
        ],
      ),
    );
  }
}
