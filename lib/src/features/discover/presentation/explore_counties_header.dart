import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import 'explore_styles.dart';

/// Which counties the Counties view lists.
enum ExploreCountyScope { all, mine, open }

/// The Counties view's top block (design frame 3a): "5 of 47 counties
/// claimed" and the All / Mine / Open chips with counts.
class ExploreCountiesHeader extends StatelessWidget {
  const ExploreCountiesHeader({
    super.key,
    required this.claimed,
    required this.total,
    required this.scope,
    required this.onScopeChanged,
  });

  final int claimed;
  final int total;
  final ExploreCountyScope scope;
  final ValueChanged<ExploreCountyScope> onScopeChanged;

  @override
  Widget build(BuildContext context) {
    final counts = {
      ExploreCountyScope.all: total,
      ExploreCountyScope.mine: claimed,
      ExploreCountyScope.open: total - claimed,
    };
    const labels = {
      ExploreCountyScope.all: 'All',
      ExploreCountyScope.mine: 'Mine',
      ExploreCountyScope.open: 'Open',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$claimed',
                  style: const TextStyle(color: AppColors.accent),
                ),
                TextSpan(text: ' of $total counties explored'),
              ],
            ),
            style: ExploreStyles.resultsSentence,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final value in ExploreCountyScope.values) ...[
                if (value != ExploreCountyScope.values.first)
                  const SizedBox(width: 8),
                _ScopeChip(
                  label: '${labels[value]} ${counts[value]}',
                  selected: value == scope,
                  onTap: () => onScopeChanged(value),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.accent : AppColors.exploreSurface,
    shape: StadiumBorder(
      side: BorderSide(
        color: selected ? AppColors.accent : AppColors.exploreBorder,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            child: Text(
              label,
              style: AppTypeScale.pill.copyWith(
                color: selected ? Colors.white : AppColors.exploreMutedText,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
