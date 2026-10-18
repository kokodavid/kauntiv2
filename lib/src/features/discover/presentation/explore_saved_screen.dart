import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/county_badge_medallion.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../application/explore_providers.dart';
import '../domain/explore_board.dart';
import '../domain/explore_entries.dart';
import '../domain/explore_lists.dart';
import 'explore_field_row.dart';
import 'explore_place_row.dart';
import 'explore_styles.dart';

/// Saved, opened from the header bookmark (design frame 3b): its own screen
/// with a back arrow and a "1 of 2 seen" count, grouped by county so the
/// list also shows which new badges a trip would earn.
class ExploreSavedScreen extends ConsumerWidget {
  const ExploreSavedScreen({
    super.key,
    required this.board,
    required this.onBack,
    this.onOpenPlace,
  });

  final ExploreBoard board;
  final VoidCallback onBack;
  final OpenExplorePlace? onOpenPlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = [
      for (final group in board.saved)
        if (group.places.isNotEmpty) group,
    ];
    final places = [for (final group in groups) ...group.places];
    final ticked = ref.watch(exploreTickedPlacesProvider);
    final seen = places.where((p) => ticked[p.id] ?? p.seen).length;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        AppBottomNav.clearance(context) + 24,
      ),
      children: [
        Row(
          children: [
            AppBackButton(onPressed: onBack),
            const Spacer(),
            if (places.isNotEmpty)
              Text(
                '$seen of ${places.length} seen',
                style: const TextStyle(
                  fontFamily: AppTypeScale.family,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mutedForeground,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Saved', style: ExploreStyles.resultsSentence),
        const SizedBox(height: 16),
        if (groups.isEmpty)
          const Text(
            'Bookmark a place and it shows up here.',
            style: ExploreStyles.emptyBody,
          ),
        for (final group in groups) ...[
          _GroupHeader(group: group),
          const SizedBox(height: 10),
          for (final place in group.places) ...[
            ExploreFieldRow(
              saved: true,
              onOpen: onOpenPlace,
              entry: ExploreEntry(
                place: place,
                countyCode: group.county.code,
                countyName: group.county.name,
                claimed: _claimed(group),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
        ],
        if (groups.isNotEmpty)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info, size: 16, color: AppColors.mutedForeground),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You tick places yourself. The app only knows which county '
                  'you were in, never where you stood.',
                  style: ExploreStyles.savedMeta,
                ),
              ),
            ],
          ),
      ],
    );
  }

  static bool _claimed(ExploreSavedGroup group) =>
      group.status == ExploreSavedStatus.badgeEarned ||
      group.status == ExploreSavedStatus.localExpert;
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final ExploreSavedGroup group;

  @override
  Widget build(BuildContext context) {
    final county = CountyPaths.byCode[group.county.code];
    final claimed = ExploreSavedScreen._claimed(group);
    return Row(
      children: [
        if (county != null)
          CountyBadgeMedallion(county: county, earned: claimed, size: 20),
        const SizedBox(width: 8),
        Text(
          group.county.name.toUpperCase(),
          style: const TextStyle(
            fontFamily: AppTypeScale.family,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: .5,
            color: AppColors.exploreText,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          claimed ? '· claimed' : '· not claimed yet',
          style: const TextStyle(
            fontFamily: AppTypeScale.family,
            fontSize: 11,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: SizedBox(
            height: 1,
            child: ColoredBox(color: AppColors.exploreBorder),
          ),
        ),
      ],
    );
  }
}
