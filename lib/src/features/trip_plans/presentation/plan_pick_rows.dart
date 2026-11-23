import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// A row in a "pick one" sheet (Add to day, Move to, Add to trip): an
/// optional leading mark, a title and a quiet line, divided by a hairline.
class PlanPickRow extends StatelessWidget {
  const PlanPickRow({
    super.key,
    required this.title,
    required this.detail,
    required this.onTap,
    this.leading,
    this.trailing,
  });

  final String title;
  final String detail;

  /// Null greys the row out.
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;

  /// The small coloured dot that marks a day.
  static Widget dot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? 0.5 : 1,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.exploreBorder)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypeScale.itemTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: AppTypeScale.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    ),
  );
}

/// A blue action row at the end of a pick sheet ("New day", "New plan").
class PlanPickLinkRow extends StatelessWidget {
  const PlanPickLinkRow({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.exploreBorder)),
      ),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, size: 20, color: AppColors.accent)
          else
            const SizedBox(width: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypeScale.action.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    ),
  );
}
