import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/place_type.dart';
import '../../../core/widgets/county_badge_medallion.dart';
import '../../../core/widgets/place_type_style.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../application/explore_providers.dart';
import '../domain/explore_entries.dart';
import 'explore_place_row.dart';
import 'explore_styles.dart';

/// Search with nothing found (design frame 2d): says what search covers,
/// suggests a shorter query, and offers browse pills for any word of the
/// query that matches a place type or a county.
class ExploreSearchEmpty extends ConsumerWidget {
  const ExploreSearchEmpty({
    super.key,
    required this.query,
    required this.entries,
    required this.onBrowseType,
    this.onOpenCounty,
  });

  final String query;
  final List<ExploreEntry> entries;
  final ValueChanged<String> onBrowseType;
  final OpenExploreCounty? onOpenCounty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = [
      for (final word in query.toLowerCase().split(RegExp(r'\s+')))
        if (word.length >= 3) word,
    ];
    final counts = <String, int>{};
    for (final entry in entries) {
      final key = entry.place.category.key;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final types = [
      for (final type in PlaceType.all)
        if (type.isListed &&
            (counts[type.key] ?? 0) > 0 &&
            words.any(
              (w) =>
                  type.label.toLowerCase().contains(w) ||
                  type.pluralLabel.toLowerCase().contains(w),
            ))
          type,
    ];
    final counties = [
      for (final county in CountyPaths.all)
        if (words.any((w) => county.name.toLowerCase().contains(w))) county,
    ].take(4).toList();
    final first = words.isEmpty ? 'mara' : words.first;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nothing matches “${query.trim()}”',
            style: ExploreStyles.resultsSentence,
          ),
          const SizedBox(height: 12),
          Text(
            'Search looks at place and county names. Try one word, like '
            '“$first”.',
            style: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 13,
              height: 1.5,
              color: AppColors.mutedForeground,
            ),
          ),
          if (types.isNotEmpty || counties.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'OR BROWSE',
              style: TextStyle(
                fontFamily: AppTypeScale.family,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: .5,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final type in types)
                  _BrowsePill(
                    label: '${type.pluralLabel} · ${counts[type.key]}',
                    leading: Icon(
                      type.icon,
                      size: 17,
                      color: AppColors.mutedForeground,
                    ),
                    onTap: () {
                      ref.read(exploreSearchQueryProvider.notifier).update('');
                      onBrowseType(type.key);
                    },
                  ),
                for (final county in counties)
                  _BrowsePill(
                    label: county.name,
                    leftPadding: 6,
                    leading: CountyBadgeMedallion(
                      county: county,
                      earned: false,
                      size: 24,
                    ),
                    onTap: () => onOpenCounty?.call(context, county.code),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BrowsePill extends StatelessWidget {
  const _BrowsePill({
    required this.label,
    required this.leading,
    required this.onTap,
    this.leftPadding = 10,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;
  final double leftPadding;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.exploreSurface,
    shape: const StadiumBorder(
      side: BorderSide(color: AppColors.exploreBorder),
    ),
    child: InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: EdgeInsets.fromLTRB(leftPadding, 0, 12, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypeScale.pill.copyWith(
                  color: AppColors.exploreMutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
