import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_save_icon.dart';
import '../../../core/widgets/county_badge_medallion.dart';
import '../../../core/widgets/place_type_style.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../application/explore_providers.dart';
import '../domain/explore_entries.dart';
import '../domain/explore_labels.dart';
import 'explore_place_row.dart';
import 'explore_styles.dart';

/// The Field Guide result row (design "Field Card v2", variant "row"):
/// white card, minimum 96 high, 72 pt thumbnail or type-icon tile, name,
/// "Waterfall . 94 km away", county badge with claim state, bookmark.
class ExploreFieldRow extends ConsumerWidget {
  const ExploreFieldRow({
    super.key,
    required this.entry,
    this.onOpen,
    this.saved = false,
  });

  final ExploreEntry entry;
  final OpenExplorePlace? onOpen;

  /// The Saved screen's row: a tick box in front and a 56 pt thumbnail.
  final bool saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = entry.place;
    final county = CountyPaths.byCode[entry.countyCode];
    final bookmarked = ref.watch(
      exploreSavedPlacesProvider.select((values) => values[place.id]),
    );
    // Saved rows: this session's tick wins over what the board loaded.
    final override = saved
        ? ref.watch(exploreTickedPlacesProvider.select((m) => m[place.id]))
        : null;
    final seen = override ?? place.seen;
    // A place already seen has no "N km away": the trip is done.
    final meta = [
      place.category.label,
      if (!(saved && seen)) ?place.distanceLabel,
    ].join(' · ');
    final seenDate = override == true ? DateTime.now() : place.seenAt;
    return Material(
      color: AppColors.exploreSurface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen == null ? null : () => onOpen!(context, place.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                if (saved) _TickBox(placeId: place.id, ticked: seen),
                _Thumb(
                  url: place.thumbnailUrl,
                  icon: place.category.icon,
                  size: saved ? 56 : 72,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              place.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ExploreStyles.rowTitle,
                            ),
                          ),
                          if (place.isPromoted) ...[
                            const SizedBox(width: 6),
                            _PromotionPill(label: place.promotionLabel),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text.rich(
                        TextSpan(
                          text: meta,
                          children: [
                            if (saved && seen)
                              TextSpan(
                                text:
                                    ' · Seen'
                                    '${seenDate == null ? '' : ' ${ExploreLabels.dayMonth(seenDate)}'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.exploreSeen,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ExploreStyles.rowMeta,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (county != null)
                            CountyBadgeMedallion(
                              county: county,
                              earned: entry.claimed,
                              size: 20,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            entry.countyName,
                            style: ExploreStyles.rowCounty,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '· ${entry.claimed ? 'claimed' : 'not claimed yet'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ExploreStyles.rowMeta,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSaveIcon(
                  saved: bookmarked ?? place.saved,
                  dimension: 44,
                  iconSize: 22,
                  unsavedColor: AppColors.mutedForeground,
                  onChanged: (next) => ref
                      .read(exploreSavedPlacesProvider.notifier)
                      .setSaved(
                        countyCode: entry.countyCode,
                        placeId: place.id,
                        saved: next,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.icon, required this.size});

  final String? url;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.exploreCategoryFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 28, color: AppColors.exploreCategoryText),
    );
    return SizedBox.square(
      dimension: size,
      child: url == null
          ? tile
          : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image(
                image: appNetworkImage(url!, cacheWidth: 216),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => tile,
              ),
            ),
    );
  }
}

class _TickBox extends ConsumerWidget {
  const _TickBox({required this.placeId, required this.ticked});

  final String placeId;
  final bool ticked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      checked: ticked,
      label: 'Seen',
      child: InkResponse(
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref
                .read(exploreTickedPlacesProvider.notifier)
                .setTicked(placeId: placeId, ticked: !ticked);
          } on Object catch (error) {
            debugPrint('Tick failed for $placeId: $error');
            messenger.showSnackBar(
              const SnackBar(content: Text("Couldn't update that tick.")),
            );
          }
        },
        child: SizedBox(
          width: 32,
          height: 44,
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: ticked
                      ? AppColors.exploreSeen
                      : AppColors.trackInactive,
                  width: 2,
                ),
                color: ticked ? AppColors.exploreSeen : Colors.white,
              ),
              child: ticked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _PromotionPill extends StatelessWidget {
  const _PromotionPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.explorePromotionFill,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        label,
        style: ExploreStyles.fieldPlaceBadge.copyWith(
          color: AppColors.explorePromotionText,
        ),
      ),
    ),
  );
}
