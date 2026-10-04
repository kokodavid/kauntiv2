import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../domain/county_safety_feed.dart';

class CountySafetyIncidentTile extends StatelessWidget {
  const CountySafetyIncidentTile({
    super.key,
    required this.incident,
    required this.onTap,
  });

  final CountySafetyIncident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              incident.isSevere
                  ? const _SeverityTag()
                  : _Tag(label: _label(incident.category)),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  '${_reportedLabel(incident.reportedAt)} · '
                  '${_label(incident.sourceName)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.small,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            incident.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypeScale.cardTitle,
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              if (incident.locationName.isNotEmpty) ...[
                Text(incident.locationName, style: AppTypeScale.small),
                const SizedBox(width: 12),
              ],
              Text(
                incident.reportCount > 1
                    ? 'Reported by ${incident.reportCount} outlets'
                    : 'Single source',
                style: AppTypeScale.small,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SeverityTag extends StatelessWidget {
  const _SeverityTag();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.danger,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        'High severity',
        style: TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: AppTypeScale.smallSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.lockedFill,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTypeScale.family,
          fontSize: AppTypeScale.smallSize,
          fontWeight: FontWeight.w700,
          color: AppColors.foreground,
        ),
      ),
    ),
  );
}

String _label(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _reportedLabel(DateTime reportedAt) {
  final hours = DateTime.now().difference(reportedAt).inHours;
  if (hours < 1) return 'Just now';
  if (hours < 24) return '$hours ${hours == 1 ? 'hr' : 'hrs'} ago';
  return _date(reportedAt);
}

String _date(DateTime date) => '${date.day} ${_month(date.month)}';

String _month(int month) => const [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
][month - 1];
