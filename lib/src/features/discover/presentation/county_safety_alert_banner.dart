import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/discover_detail_actions.dart';
import '../domain/county_safety_feed.dart';
import 'county_safety_news_sheet.dart';

class CountySafetyAlertBanner extends StatelessWidget {
  const CountySafetyAlertBanner({
    super.key,
    required this.countyName,
    required this.countySlug,
    required this.feed,
    required this.actions,
  });

  final String countyName;
  final String countySlug;
  final Future<CountySafetyFeed> feed;
  final DiscoverDetailActions actions;

  @override
  Widget build(BuildContext context) => FutureBuilder<CountySafetyFeed>(
    key: ValueKey(countyName),
    future: feed,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();
      final incident = snapshot.data!.activeAlert;
      if (incident == null) return const SizedBox.shrink();
      final severe = incident.isSevere;
      final background = severe
          ? AppColors.dangerTint
          : AppColors.mapDetectedStopFill;
      final foreground = severe
          ? AppColors.dangerSoftForeground
          : AppColors.mapDetectedStopOutline;
      return Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showCountySafetyNewsSheet(
            context,
            countyName: countyName,
            countySlug: countySlug,
            feed: snapshot.data!,
            actions: actions,
            pinnedIncident: incident,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  severe ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: foreground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        severe
                            ? 'HIGH SEVERITY · LAST 48 HRS'
                            : 'ADVISORY · LAST 48 HRS',
                        style: AppTypeScale.sectionLabel.copyWith(
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        incident.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeScale.itemTitle.copyWith(
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Reported by ${incident.reportCount} outlets · '
                        '${_age(incident.reportedAt)}',
                        style: AppTypeScale.small,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, color: foreground),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String _age(DateTime reportedAt) {
  final hours = DateTime.now().difference(reportedAt).inHours;
  if (hours < 1) return 'Just now';
  if (hours < 24) return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  final days = hours ~/ 24;
  return days == 1 ? 'Yesterday' : '$days days ago';
}
