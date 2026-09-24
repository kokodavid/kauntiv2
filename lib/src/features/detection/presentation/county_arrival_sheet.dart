import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/app_stat_format.dart';
import '../../../core/widgets/app_feature_card.dart';
import '../../../core/widgets/app_place_row.dart';
import '../../../design/app_colors.dart';
import '../../discover/application/explore_providers.dart';
import '../../discover/domain/county_detail.dart';

/// The "you've crossed into X" sheet (v1 `county_arrival_sheet.dart`,
/// doc 03 board 15d) in the v2 card design: the heading, the county as
/// the shared [AppFeatureCard] (tap for County Detail), up to four places
/// as shared [AppPlaceRow]s (saved first), a link to all of them, the
/// privacy note and Dismiss. [data] is already loaded, so the sheet opens
/// complete.
///
/// [onOpenCounty] and [onOpenPlace] run after the sheet closes; null
/// leaves those taps inert (no detail pages in this build).
Future<void> showCountyArrivalSheet(
  BuildContext context, {
  required CountyDetailData data,
  void Function(int countyCode)? onOpenCounty,
  void Function(String placeId)? onOpenPlace,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.pageBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      void closeThen(VoidCallback action) {
        Navigator.of(sheetContext).pop();
        action();
      }

      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.88,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _ArrivalContent(
              data: data,
              onOpenCounty: onOpenCounty == null
                  ? null
                  : () => closeThen(() => onOpenCounty(data.county.code)),
              onOpenPlace: onOpenPlace == null
                  ? null
                  : (id) => closeThen(() => onOpenPlace(id)),
              onDismiss: () => Navigator.of(sheetContext).pop(),
            ),
          ),
        ),
      );
    },
  );
}

class _ArrivalContent extends StatelessWidget {
  const _ArrivalContent({
    required this.data,
    required this.onDismiss,
    this.onOpenCounty,
    this.onOpenPlace,
  });

  /// v1's design showed four places.
  static const _maxPlaces = 4;

  final CountyDetailData data;
  final VoidCallback onDismiss;
  final VoidCallback? onOpenCounty;
  final void Function(String placeId)? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final name = data.county.name;
    final count = data.places.length;
    final facts = data.quickFacts;
    final hq = facts.headquarters;
    // Saved first, otherwise the county's own order.
    final places = [
      ...data.places.where((p) => p.saved),
      ...data.places.where((p) => !p.saved),
    ].take(_maxPlaces).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome to $name', style: AppTypeScale.sectionTitle),
              const SizedBox(height: 2),
              Text(switch (count) {
                0 => "You've just crossed in. Nothing on file here yet.",
                1 => "You've just crossed in. 1 place worth the detour.",
                _ => "You've just crossed in. $count places worth the detour.",
              }, style: AppTypeScale.body),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppFeatureCard(
          county: data.county,
          label: "YOU'RE HERE",
          photoTitle: name,
          photoCaption: hq == null ? '$name County' : 'HQ · $hq',
          photoUrl: data.highlightImageUrl,
          line: data.aboutBlurb,
          stats: AppStatFormat.stats(
            areaKm2: facts.areaKm2,
            elevationM: facts.elevationM,
          ),
          onTap: onOpenCounty ?? () {},
        ),
        if (places.isNotEmpty) ...[
          const SizedBox(height: 12),
          _PlacesCard(
            data: data,
            places: places,
            onOpenPlace: onOpenPlace,
            onOpenCounty: onOpenCounty,
          ),
        ],
        const SizedBox(height: 12),
        _PrivacyNote(countyName: name),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mutedForeground,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Dismiss', style: AppTypeScale.action),
          ),
        ),
      ],
    );
  }
}

/// "Places to visit": the shared place rows in a white card, like
/// Explore's county cards, with the link to the full list.
class _PlacesCard extends ConsumerWidget {
  const _PlacesCard({
    required this.data,
    required this.places,
    this.onOpenPlace,
    this.onOpenCounty,
  });

  final CountyDetailData data;
  final List<CountyDetailPlace> places;
  final void Function(String placeId)? onOpenPlace;
  final VoidCallback? onOpenCounty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(exploreSavedPlacesProvider);
    final open = onOpenPlace;
    final count = data.places.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: AppColors.exploreSurface,
        border: Border.all(color: AppColors.exploreBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Places to visit', style: AppTypeScale.cardTitle),
          for (final (i, place) in places.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.exploreBorder),
            AppPlaceRow(
              title: place.title,
              description: place.description,
              categoryLabel: place.category.label,
              thumbnailUrl: place.thumbnailUrl,
              saved: saved[place.id] ?? place.saved,
              onTap: open == null ? null : () => open(place.id),
              onSaveChanged: (value) => ref
                  .read(exploreSavedPlacesProvider.notifier)
                  .setSaved(
                    countyCode: data.county.code,
                    placeId: place.id,
                    saved: value,
                  ),
            ),
          ],
          if (onOpenCounty case final openCounty?) ...[
            const Divider(height: 1, color: AppColors.exploreBorder),
            InkWell(
              onTap: openCounty,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'All $count ${count == 1 ? 'place' : 'places'} in '
                    '${data.county.name} →',
                    style: AppTypeScale.action,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Doc 05: the app knows the county, never the spot inside it.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.countyName});

  final String countyName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.exploreCategoryFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 15,
            color: AppColors.exploreCategoryText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "We know you're in $countyName, not where you are in it.",
              style: AppTypeScale.small.copyWith(
                color: AppColors.exploreCategoryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
