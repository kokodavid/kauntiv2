import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_county_shape.dart';
import '../application/explore_providers.dart';
import '../domain/explore_lists.dart';
import 'explore_place_row.dart';
import 'explore_styles.dart';

/// UNCLAIMED's featured card, "CLOSEST ONE YOU DON'T HAVE" (v1
/// `_FeaturedUnclaimedCard`): the county photo with name and blurb when
/// there is one, otherwise the dashed county shape, distance and blurb;
/// then "See what's there" and a county Save toggle.
class ExploreClosestCard extends StatelessWidget {
  const ExploreClosestCard({super.key, required this.entry, this.onOpenCounty});

  final ExploreUnclaimedCounty entry;
  final OpenExploreCounty? onOpenCounty;

  @override
  Widget build(BuildContext context) {
    final imageUrl = entry.highlightImageUrl;
    final actions = _ActionRow(entry: entry, onOpenCounty: onOpenCounty);
    return Container(
      decoration: ExploreStyles.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: _NoPhotoBody(entry: entry, actions: actions),
            )
          : Column(
              children: [
                _PhotoHeader(imageUrl: imageUrl, entry: entry),
                Padding(padding: const EdgeInsets.all(16), child: actions),
              ],
            ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.imageUrl, required this.entry});

  final String imageUrl;
  final ExploreUnclaimedCounty entry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const ColoredBox(color: AppColors.explorePhotoPlaceholder),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: .72),
                  Colors.transparent,
                ],
                stops: const [0, .6],
              ),
            ),
          ),
          const Positioned(left: 16, top: 14, child: _ClosestPill()),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.county.name, style: ExploreStyles.photoTitle),
                const SizedBox(height: 4),
                Text(
                  entry.blurb,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ExploreStyles.photoBlurb,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPhotoBody extends StatelessWidget {
  const _NoPhotoBody({required this.entry, required this.actions});

  final ExploreUnclaimedCounty entry;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ClosestPill(),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 44,
              height: 52,
              child: AppCountyShape(
                county: entry.county,
                fill: Colors.white,
                stroke: AppColors.trackInactive,
                strokeWidth: 1.4,
                dashed: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(entry.county.name, style: ExploreStyles.countyTitle),
            ),
          ],
        ),
        if (entry.distanceLabel case final distance?) ...[
          const SizedBox(height: 4),
          Text(distance, style: ExploreStyles.countyMeta),
        ],
        const SizedBox(height: 10),
        Text(entry.blurb, style: ExploreStyles.emptyBody),
        const SizedBox(height: 14),
        actions,
      ],
    );
  }
}

class _ClosestPill extends StatelessWidget {
  const _ClosestPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.exploreSurface,
        border: Border.all(color: AppColors.exploreBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        "CLOSEST ONE YOU DON'T HAVE",
        style: ExploreStyles.link,
      ),
    );
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.entry, this.onOpenCounty});

  final ExploreUnclaimedCounty entry;
  final OpenExploreCounty? onOpenCounty;

  Future<void> _toggleSaved(
    BuildContext context,
    WidgetRef ref,
    bool saved,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(exploreSavedCountiesProvider.notifier)
          .setSaved(countyCode: entry.county.code, saved: !saved);
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't update your saved counties.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved =
        ref.watch(
          exploreSavedCountiesProvider.select((m) => m[entry.county.code]),
        ) ??
        entry.isSavedAlone;
    final openCounty = onOpenCounty;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: FilledButton(
              onPressed: openCounty == null
                  ? null
                  : () => openCounty(context, entry.county.code),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: shape,
              ),
              child: Text(
                "See what's there",
                style: AppTextStyles.buttonLabel.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: OutlinedButton(
            onPressed: () => _toggleSaved(context, ref, saved),
            style: OutlinedButton.styleFrom(
              backgroundColor: saved
                  ? AppColors.secondaryFill
                  : AppColors.exploreSurface,
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: shape,
            ),
            child: Text(
              saved ? 'Saved' : 'Save',
              style: AppTextStyles.buttonLabel.copyWith(
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
