import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_glyph_icon.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../application/discover_detail_actions.dart';
import '../domain/county_safety_feed.dart';
import 'county_safety_news_sheet.dart';

class CountySafetySection extends StatelessWidget {
  const CountySafetySection({
    super.key,
    required this.countyName,
    required this.countySlug,
    required this.feed,
    required this.actions,
    required this.onRetry,
  });

  final String countyName;
  final String countySlug;
  final Future<CountySafetyFeed> feed;
  final DiscoverDetailActions actions;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<CountySafetyFeed>(
    key: ValueKey(countyName),
    future: feed,
    builder: (context, snapshot) {
      if (snapshot.hasError) return _ErrorRow(onRetry: onRetry);
      if (!snapshot.hasData) return const _LoadingRow();
      final value = snapshot.data!;
      final latest = value.latestIncident;
      return Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showCountySafetyNewsSheet(
            context,
            countyName: countyName,
            countySlug: countySlug,
            feed: value,
            actions: actions,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NewsIcon(alert: value.activeAlert),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('In the news', style: AppTypeScale.cardTitle),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${value.incidentCount} '
                              '${value.incidentCount == 1 ? 'report' : 'reports'} '
                              // 30: DeckwatchCountySafetyRepository.windowDays
                              // (data layer -- presentation can't import it;
                              // keep these in sync if the window changes).
                              '· 30 days',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypeScale.small,
                            ),
                          ),
                        ],
                      ),
                      if (latest != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Latest: ${latest.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypeScale.body,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// The newspaper tile: Lucide's `newspaper`, 20px, `AppColors.toastNeutralIcon`
/// (#3F3F46), on a 40px light-grey rounded tile. The corner dot shows only
/// while [alert] (the feed's [CountySafetyFeed.activeAlert]) is non-null --
/// red for a severe incident, amber otherwise -- not a plain "there are
/// reports" presence marker.
class _NewsIcon extends StatelessWidget {
  const _NewsIcon({required this.alert});

  final CountySafetyIncident? alert;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 40,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.iconButtonBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const AppGlyphIcon(
            path: AppGlyphPaths.newspaper,
            color: AppColors.toastNeutralIcon,
            size: 20,
          ),
        ),
        if (alert != null)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: alert!.isSevere ? AppColors.danger : AppColors.toastWarningIcon,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    ),
  );
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    alignment: Alignment.centerLeft,
    child: const Text('Loading news…', style: AppTypeScale.body),
  );
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text("Couldn't load county news.", style: AppTypeScale.body),
        ),
        IconButton(
          tooltip: 'Retry loading county news',
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, color: AppColors.accent),
        ),
      ],
    ),
  );
}
