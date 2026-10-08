import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// Every Home sheet section's header: a blue caps kicker, a title and an
/// optional action on the right.
class MapHomeSectionHeading extends StatelessWidget {
  const MapHomeSectionHeading({
    super.key,
    required this.kicker,
    required this.title,
    this.trailing,
  });

  final String kicker;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker,
                style: AppTypeScale.sectionLabel.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(title, style: AppTypeScale.sectionTitle),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// The section action ("All 34 left"), at least 44 pt tall to tap.
class MapHomeSectionAction extends StatelessWidget {
  const MapHomeSectionAction({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTypeScale.small),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
