import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// "Archived · 2": one quiet row at the bottom of Planned that opens and
/// closes the shelved plans, so they never compete with real ones.
class PlannedArchivedRow extends StatelessWidget {
  const PlannedArchivedRow({
    super.key,
    required this.count,
    required this.open,
    required this.onTap,
  });

  final int count;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Semantics(
      button: true,
      expanded: open,
      child: Material(
        color: AppColors.exploreSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.exploreBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.archive_outlined,
                  size: 20,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Archived', style: AppTypeScale.itemTitle),
                ),
                Text('$count', style: AppTypeScale.small),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.faintForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
