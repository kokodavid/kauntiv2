import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/explore_filters.dart';
import 'explore_styles.dart';

/// Removable filter pills (accent tint, x) with "Clear all".
class ExploreFilterPills extends StatelessWidget {
  const ExploreFilterPills({
    super.key,
    required this.filters,
    required this.countyName,
    required this.onChanged,
  });

  final ExploreFilters filters;
  final String? countyName;
  final ValueChanged<ExploreFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (filters.typeKeys != null)
          _RemovablePill(
            label: filters.typeKeysLabel ?? 'For you',
            onRemove: () => onChanged(filters.copyWith(clearTypeKeys: true)),
          ),
        if (filters.unclaimedOnly)
          _RemovablePill(
            label: 'Not claimed',
            onRemove: () => onChanged(filters.copyWith(unclaimedOnly: false)),
          ),
        if (filters.maxKm != null)
          _RemovablePill(
            label: 'Under ${filters.maxKm} km',
            onRemove: () => onChanged(filters.copyWith(clearMaxKm: true)),
          ),
        if (filters.countyCode != null)
          _RemovablePill(
            label: 'In ${countyName ?? 'county'}',
            onRemove: () => onChanged(filters.copyWith(clearCounty: true)),
          ),
        TextButton(
          onPressed: () => onChanged(ExploreFilters(typeKey: filters.typeKey)),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Clear all'),
        ),
      ],
    );
  }
}

class _RemovablePill extends StatelessWidget {
  const _RemovablePill({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Remove filter $label',
    child: Material(
      color: ExploreStyles.filterPillFill,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onRemove,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shrinks with an ellipsis, so a long label can't push the
                // pill past the screen edge.
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeScale.pill.copyWith(
                      color: ExploreStyles.filterPillText,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: ExploreStyles.filterPillText,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// "That's all under 150 km. 5 more further out." with a button that widens
/// the limit to the next stop.
class ExploreFurtherFooter extends StatelessWidget {
  const ExploreFurtherFooter({
    super.key,
    required this.maxKm,
    required this.furtherCount,
    required this.nextStopKm,
    required this.onShowMore,
  });

  final int maxKm;
  final int furtherCount;
  final int? nextStopKm;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
    decoration: ExploreStyles.cardDecoration,
    child: Row(
      children: [
        Expanded(
          child: Text(
            "That's all under $maxKm km. $furtherCount more further out.",
            style: AppTypeScale.body.copyWith(
              height: 1.45,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.accentTint,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onShowMore,
            customBorder: const StadiumBorder(),
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    nextStopKm == null ? 'Show all' : 'Show $nextStopKm km',
                    style: const TextStyle(
                      fontFamily: AppTypeScale.family,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
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

/// Shown when the filters leave nothing.
class ExploreNoMatches extends StatelessWidget {
  const ExploreNoMatches({
    super.key,
    required this.filters,
    required this.onClear,
  });

  final ExploreFilters filters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: ExploreStyles.cardDecoration,
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Nothing matches these filters yet.',
            style: ExploreStyles.emptyBody,
          ),
        ),
        TextButton(onPressed: onClear, child: const Text('Clear all')),
      ],
    ),
  );
}
