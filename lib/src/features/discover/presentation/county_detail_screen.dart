import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_county_shape.dart';
import '../application/discover_detail_actions.dart';
import '../domain/county_detail.dart';
import '../domain/place_category.dart';
import 'county_detail_facts.dart';
import 'county_place_filters.dart';
import 'detail_async_body.dart';
import 'detail_photo_carousel.dart';
import 'detail_widgets.dart';
import 'explore_place_row.dart';
import 'place_photo_card.dart';

/// County Detail (v2 Figma node 235:7261, ported from v1): photo carousel
/// with back button, centred county name and the traveller's status chip;
/// title, stats and the county shape; a short blurb; a Governor /
/// Headquarters / Source card; and "Places to See".
class CountyDetailScreen extends StatelessWidget {
  const CountyDetailScreen({
    super.key,
    required this.countyCode,
    required this.actions,
    this.onOpenPlace,
  });

  final int countyCode;
  final DiscoverDetailActions actions;

  /// Place Detail for a tapped place, supplied from `app/` (the
  /// `/place/:id` route). Null leaves the cards inert.
  final OpenExplorePlace? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: DetailAsyncBody<CountyDetailData>(
          load: () => actions.countyDetail(countyCode),
          errorMessage: "Couldn't load this county.",
          builder: (context, data) =>
              _CountyDetailBody(
                data: data,
                actions: actions,
                onOpenPlace: onOpenPlace,
              ),
        ),
      ),
    );
  }
}

class _CountyDetailBody extends StatefulWidget {
  const _CountyDetailBody({
    required this.data,
    required this.actions,
    this.onOpenPlace,
  });

  final CountyDetailData data;
  final DiscoverDetailActions actions;
  final OpenExplorePlace? onOpenPlace;

  @override
  State<_CountyDetailBody> createState() => _CountyDetailBodyState();
}

class _CountyDetailBodyState extends State<_CountyDetailBody> {
  /// The place filter; null is All.
  PlaceCategory? _category;

  /// Saves made here, so a card filtered out and back shows its latest
  /// state rather than the loaded one.
  final Map<String, bool> _saved = {};

  CountyDetailPlace _withSaved(CountyDetailPlace place) => CountyDetailPlace(
    id: place.id,
    title: place.title,
    description: place.description,
    category: place.category,
    saved: _saved[place.id] ?? place.saved,
    thumbnailUrl: place.thumbnailUrl,
  );

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final actions = widget.actions;
    final category = _category;
    final places = category == null
        ? data.places
        : [
            for (final place in data.places)
              if (place.category == category) place,
          ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(7, 8, 7, 32),
      children: [
        AspectRatio(
          aspectRatio: 382 / 528,
          child: DetailPhotoCarousel(
            images: data.slideshowImages,
            overlay: _CountyPhotoChrome(
              title: data.county.name,
              statusLabel: data.personalStatusLabel,
            ),
          ),
        ),
        const SizedBox(height: 19),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleRow(data: data),
              const SizedBox(height: 20),
              Text(data.aboutBlurb, style: AppTextStyles.detailBody),
              const SizedBox(height: 11),
              DetailFactCard(
                facts: [
                  ('Governor', data.quickFacts.governorName),
                  ('Headquarters', data.quickFacts.headquarters),
                  ('Source', 'Kaunti47'),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'Places to See',
                style: AppTextStyles.detailSectionTitle,
              ),
              const SizedBox(height: 11),
              const Text(
                'Listings marked AD are paid placements. Places to see are '
                'never paid -- they come from KWS, UNESCO and OpenStreetMap.',
                style: AppTextStyles.detailBody,
              ),
              const SizedBox(height: 9),
              if (data.places.isEmpty)
                Text(
                  'No places on file yet for ${data.county.name}.',
                  style: AppTextStyles.detailBody,
                )
              else ...[
                CountyPlaceFilters(
                  places: data.places,
                  selected: category,
                  onSelected: (next) => setState(() => _category = next),
                ),
                const SizedBox(height: 12),
                for (final place in places) ...[
                  PlacePhotoCard(
                    key: ValueKey(place.id),
                    place: _withSaved(place),
                    onTap: () => widget.onOpenPlace?.call(context, place.id),
                    onSavedChanged: (saved) async {
                      await actions.setPlaceSaved(
                        countyCode: data.county.code,
                        placeId: place.id,
                        saved: saved,
                      );
                      _saved[place.id] = saved;
                    },
                  ),
                  const SizedBox(height: 9),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Title, divider and stats on the left; the county's own shape in a white
/// squircle on the right, solid when explored and dashed when not.
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.data});

  final CountyDetailData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.county.name, style: AppTextStyles.detailTitle),
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.factCardBorder),
              const SizedBox(height: 10),
              CountyStatsRow(facts: data.quickFacts),
            ],
          ),
        ),
        const SizedBox(width: 19),
        Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.countyShapeCardBorder),
            borderRadius: BorderRadius.circular(24),
          ),
          child: AppCountyShape(
            county: data.county,
            fill: data.isHeld ? AppColors.green : AppColors.lockedFill,
            stroke: data.isHeld ? null : AppColors.lockedStroke,
            strokeWidth: data.isHeld ? 0 : 1.2,
            dashed: !data.isHeld,
          ),
        ),
      ],
    );
  }
}

/// Back button left, county name centred on the whole photo width, status
/// chip right, pinned to the top of the photo.
class _CountyPhotoChrome extends StatelessWidget {
  const _CountyPhotoChrome({required this.title, required this.statusLabel});

  final String title;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.detailNavTitle,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: DetailBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: DetailStatusChip(label: statusLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
