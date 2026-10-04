import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/discover_detail_actions.dart';
import '../domain/county_safety_feed.dart';
import 'county_incident_summary_panel.dart';
import 'county_safety_incident_tile.dart';

Future<void> showCountySafetyNewsSheet(
  BuildContext context, {
  required String countyName,
  required String countySlug,
  required CountySafetyFeed feed,
  required DiscoverDetailActions actions,
  CountySafetyIncident? pinnedIncident,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: AppColors.sheetBackground,
  barrierColor: AppColors.sheetBarrier,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
  ),
  showDragHandle: true,
  builder: (context) => _CountySafetyNewsSheet(
    countyName: countyName,
    countySlug: countySlug,
    feed: feed,
    actions: actions,
    pinnedIncident: pinnedIncident,
  ),
);

class _CountySafetyNewsSheet extends StatelessWidget {
  const _CountySafetyNewsSheet({
    required this.countyName,
    required this.countySlug,
    required this.feed,
    required this.actions,
    this.pinnedIncident,
  });

  final String countyName;
  final String countySlug;
  final CountySafetyFeed feed;
  final DiscoverDetailActions actions;
  final CountySafetyIncident? pinnedIncident;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * .86;
    final reports = [
      ?pinnedIncident,
      ...feed.incidents.where((incident) => incident != pinnedIncident),
    ];
    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'In the news',
                          style: TextStyle(
                            fontFamily: AppTypeScale.family,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$countyName · reported incidents',
                          style: AppTypeScale.small,
                        ),
                      ],
                    ),
                  ),
                  _SheetCloseButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lockedFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Reports from news outlets, collected by DeckWatch. '
                  "Kaunti47 doesn't check them, and they aren't a safety "
                  'rating.',
                  style: AppTypeScale.body.copyWith(height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  CountyIncidentSummaryPanel(
                    key: ValueKey(countySlug),
                    countySlug: countySlug,
                    actions: actions,
                  ),
                  const SizedBox(height: 14),
                  if (reports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No reports in this period.',
                        style: AppTypeScale.body,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (var index = 0; index < reports.length; index++) ...[
                      if (index > 0)
                        const Divider(height: 1, color: AppColors.listDivider),
                      CountySafetyIncidentTile(
                        incident: reports[index],
                        onTap: () =>
                            actions.openSafetySource(reports[index].sourceUrl),
                      ),
                    ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                children: [
                  const Text(
                    'Source: DeckWatch',
                    style: AppTypeScale.statLabel,
                  ),
                  const Spacer(),
                  Text(
                    '${feed.incidentCount} listed',
                    style: AppTypeScale.statLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.lockedFill,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.close_rounded,
        size: 20,
        color: AppColors.foreground,
      ),
    ),
  );
}
