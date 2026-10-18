import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../design/app_type_scale.dart';

/// The small rounded pill used for filter-style choices (Explore's filter
/// sheet, the Share trip stat choices): blue when on, outlined when off,
/// with an optional leading icon or trailing chevron.
class AppChoicePill extends StatelessWidget {
  const AppChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.chevron = false,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool chevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.exploreMutedText;
    return Material(
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
            padding: EdgeInsets.only(left: 14, right: chevron ? 8 : 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: color),
                  const SizedBox(width: 5),
                ],
                Text(label, style: AppTypeScale.pill.copyWith(color: color)),
                if (chevron) Icon(Icons.chevron_right, size: 17, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
