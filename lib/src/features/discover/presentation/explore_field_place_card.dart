import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_place_row.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_save_icon.dart';
import '../../../core/widgets/county_badge_medallion.dart';
import '../../../core/widgets/place_type_style.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../application/explore_providers.dart';
import '../domain/explore_board.dart';
import 'explore_styles.dart';

/// The photo-first card used by Field Guide chapters.
///
/// Chapters render these at 240 x 300 in a horizontal carousel. The optional
/// wider, shorter variant is used for the lead card at the start of a chapter.
class ExploreFieldPlaceCard extends ConsumerWidget {
  const ExploreFieldPlaceCard({
    super.key,
    required this.place,
    required this.countyCode,
    required this.claimed,
    this.onOpen,
    this.width = 240,
    this.height = 300,
  });

  final ExplorePlace place;
  final int countyCode;
  final bool claimed;
  final OpenExplorePlace? onOpen;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      exploreSavedPlacesProvider.select((values) => values[place.id]),
    );
    final county = CountyPaths.byCode[countyCode];
    final imageUrl = place.thumbnailUrl;
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: imageUrl == null
              ? AppColors.exploreSurface
              : Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.exploreBorder),
          ),
          child: InkWell(
            onTap: onOpen == null ? null : () => onOpen!(context, place.id),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl case final url?)
                  Image(
                    // Decoded at 540 px for the 240 pt carousel cards (about 40% less
                    // memory than 720); the wide lead card keeps 720.
                    image: appNetworkImage(
                      url,
                      cacheWidth: width == double.infinity ? 720 : 540,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _NoPhotoBody(icon: place.category.icon),
                  )
                else
                  _NoPhotoBody(icon: place.category.icon),
                if (imageUrl != null) const _PhotoShade(),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryBadge(label: place.category.label),
                      const Spacer(),
                      _SaveButton(
                        saved: saved ?? place.saved,
                        onChanged: (next) => ref
                            .read(exploreSavedPlacesProvider.notifier)
                            .setSaved(
                              countyCode: countyCode,
                              placeId: place.id,
                              saved: next,
                            ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              place.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: ExploreStyles.fieldCardTitle(
                                onImage: imageUrl != null,
                              ),
                            ),
                          ),
                          if (place.distanceLabel case final distance?) ...[
                            const SizedBox(width: 10),
                            Text(
                              distance.replaceAll(' away', ''),
                              style: ExploreStyles.fieldCardTitle(
                                onImage: imageUrl != null,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        color: imageUrl != null
                            ? const Color(0x66FFFFFF)
                            : AppColors.exploreBorder,
                        height: 1,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _CountyBadge(county: county, claimed: claimed),
                          const SizedBox(width: 8),
                          Text(
                            county?.name ?? 'County',
                            style: ExploreStyles.fieldCardCounty(
                              onImage: imageUrl != null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '· ${claimed ? 'claimed' : 'not claimed yet'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ExploreStyles.fieldCardMeta(
                                onImage: imageUrl != null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _PhotoShade extends StatelessWidget {
  const _PhotoShade();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x22000000), Color(0xCC000000)],
        stops: [0.4, 1],
      ),
    ),
  );
}

class _NoPhotoBody extends StatelessWidget {
  const _NoPhotoBody({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.exploreSurface,
    child: Center(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.exploreCategoryFill,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: 72,
          child: Icon(icon, size: 32, color: AppColors.exploreCategoryText),
        ),
      ),
    ),
  );
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.exploreCategoryFill,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(label.toUpperCase(), style: ExploreStyles.fieldPlaceBadge),
    ),
  );
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onChanged});

  final bool saved;
  final Future<void> Function(bool saved) onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.exploreBorder),
    ),
    child: AppSaveIcon(
      saved: saved,
      dimension: 32,
      iconSize: 19,
      onChanged: onChanged,
    ),
  );
}

class _CountyBadge extends StatelessWidget {
  const _CountyBadge({required this.county, required this.claimed});

  final CountyPath? county;
  final bool claimed;

  @override
  Widget build(BuildContext context) => county == null
      ? const SizedBox.square(dimension: 20)
      : CountyBadgeMedallion(county: county!, earned: claimed, size: 20);
}
