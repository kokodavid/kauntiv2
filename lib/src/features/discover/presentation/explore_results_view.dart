import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/place_type.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/place_type_style.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../ads/domain/ad_placement.dart';
import '../domain/explore_filters.dart';
import '../domain/explore_results.dart';
import 'explore_ad_slot.dart';
import 'explore_field_row.dart';
import 'explore_place_row.dart';
import 'explore_results_parts.dart';
import 'explore_results_states.dart';
import 'explore_styles.dart';

/// Places results for a category and filters (design frame 2a): a small
/// kicker, the counted sentence, removable filter pills, then results in
/// distance bands with a "show further" footer.
class ExploreResultsView extends StatelessWidget {
  const ExploreResultsView({
    super.key,
    required this.filters,
    required this.results,
    required this.onFiltersChanged,
    this.similar = const [],
    this.onOpenPlace,
  });

  final ExploreFilters filters;
  final ExploreResults results;
  final ValueChanged<ExploreFilters> onFiltersChanged;

  /// Related types offered under a thin category.
  final List<({PlaceType type, int count})> similar;
  final OpenExplorePlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final countyName = filters.countyCode == null
        ? null
        : CountyPaths.byCode[filters.countyCode!]?.name;
    final sentence = exploreSentence(
      filters,
      results.count,
      countyName: countyName,
    );
    final type = filters.typeKey == null
        ? null
        : PlaceType.of(filters.typeKey!);
    final noRange =
        results.count == 0 &&
        filters.maxKm != null &&
        results.closest.isNotEmpty;
    final thin =
        results.count > 0 &&
        results.count < 3 &&
        filters.typeKey != null &&
        filters.sheetCount == 0;
    // Where each band starts in the whole run of rows, for ad spacing.
    final bandStarts = <int>[];
    var totalRows = 0;
    for (final band in results.bands) {
      bandStarts.add(totalRows);
      totalRows += band.entries.length;
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.list(
        children: [
          // The system back gesture leaves the results too.
          PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) onFiltersChanged(const ExploreFilters.none());
            },
            child: const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                AppBackButton(
                  onPressed: () =>
                      onFiltersChanged(const ExploreFilters.none()),
                ),
                const SizedBox(width: 12),
                if (type != null) ...[
                  Icon(type.icon, size: 18, color: AppColors.mutedForeground),
                  const SizedBox(width: 6),
                ],
                Text(
                  type == null ? 'Explore' : 'Explore · ${type.pluralLabel}',
                  style: const TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (noRange)
            Text(
              'No ${exploreNoun(filters.typeKey, 2)} under ${filters.maxKm} '
              'km. The nearest is ${results.closest.first.km!.round()} km '
              'away.',
              style: ExploreStyles.resultsSentence,
            )
          else
            Text.rich(
              TextSpan(
                style: ExploreStyles.resultsSentence,
                children: thin
                    ? [
                        const TextSpan(text: 'Only '),
                        TextSpan(
                          text: sentence.lead,
                          style: const TextStyle(color: AppColors.accent),
                        ),
                        const TextSpan(text: ' listed so far.'),
                      ]
                    : [
                        TextSpan(
                          text: sentence.lead,
                          style: const TextStyle(color: AppColors.accent),
                        ),
                        TextSpan(text: sentence.tail),
                      ],
              ),
            ),
          if (filters.sheetCount > 0) ...[
            const SizedBox(height: 12),
            ExploreFilterPills(
              filters: filters,
              countyName: countyName,
              onChanged: onFiltersChanged,
            ),
          ],
          const SizedBox(height: 20),
          if (noRange) ...[
            const ExploreRuleLabel(label: 'CLOSEST ANYWAY'),
            const SizedBox(height: 10),
            ExploreFieldRow(entry: results.closest.first, onOpen: onOpenPlace),
            const SizedBox(height: 16),
            ExplorePrimaryButton(
              label: 'Remove distance filter',
              onTap: () => onFiltersChanged(filters.copyWith(clearMaxKm: true)),
            ),
          ] else if (results.count == 0)
            ExploreNoMatches(
              filters: filters,
              onClear: () => onFiltersChanged(const ExploreFilters.none()),
            )
          else ...[
            for (var i = 0; i < results.bands.length; i++) ...[
              if (results.bands[i].label.isNotEmpty && !thin)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 8, bottom: 10),
                  child: _BandHeader(band: results.bands[i]),
                ),
              for (var j = 0; j < results.bands[i].entries.length; j++) ...[
                ExploreFieldRow(
                  entry: results.bands[i].entries[j],
                  onOpen: onOpenPlace,
                ),
                const SizedBox(height: 10),
                if (!thin &&
                    AdPlacement.afterRow(
                      index: bandStarts[i] + j,
                      total: totalRows,
                    ))
                  const ExploreAdSlot(banner: true),
              ],
            ],
            if (thin)
              ExploreSimilarTypes(
                types: similar,
                onPick: (key) => onFiltersChanged(ExploreFilters(typeKey: key)),
              ),
            if (filters.maxKm != null && results.furtherCount > 0)
              ExploreFurtherFooter(
                maxKm: filters.maxKm!,
                furtherCount: results.furtherCount,
                nextStopKm: results.nextStopKm,
                onShowMore: () => onFiltersChanged(
                  results.nextStopKm == null
                      ? filters.copyWith(clearMaxKm: true)
                      : filters.copyWith(maxKm: results.nextStopKm),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _BandHeader extends StatelessWidget {
  const _BandHeader({required this.band});

  final ExploreBand band;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(band.label, style: ExploreStyles.bandLabel),
      const SizedBox(width: 10),
      const Expanded(
        child: Divider(height: 1, thickness: 1, color: AppColors.exploreBorder),
      ),
      const SizedBox(width: 10),
      Text('${band.entries.length}', style: ExploreStyles.bandCount),
    ],
  );
}
