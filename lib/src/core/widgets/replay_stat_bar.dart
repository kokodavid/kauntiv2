import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../design/app_type_scale.dart';

/// One headline number: its value ("3.2 km") over a short label.
typedef ReplayStat = ({String value, String label});

/// A replay's headline numbers, floating where the map meets the story
/// panel below it.
class ReplayStatBar extends StatelessWidget {
  const ReplayStatBar({super.key, required this.stats});

  final List<ReplayStat> stats;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            for (final (index, entry) in stats.indexed) ...[
              if (index > 0)
                const SizedBox(
                  height: 28,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.cardBorder,
                  ),
                ),
              Expanded(
                child: _StatTile(value: entry.value, label: entry.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final parts = value.split(' ');
    final number = parts.first;
    final unit = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: number, style: AppTypeScale.compactTitle),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: AppTypeScale.small.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypeScale.statLabel),
      ],
    );
  }
}
