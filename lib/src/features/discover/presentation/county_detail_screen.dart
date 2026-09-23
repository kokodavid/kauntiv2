import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_county_shape.dart';
import '../application/discover_detail_actions.dart';
import '../domain/county_detail.dart';
import 'county_detail_facts.dart';
import 'detail_async_body.dart';
import 'detail_photo_carousel.dart';
import 'detail_widgets.dart';
import 'place_detail_screen.dart';
import 'place_photo_card.dart';

/// County Detail (v2 Figma node 235:7261, ported from v1): photo carousel
/// with back button, centred county name and the traveller's status chip;
/// title, stats and the county shape; a short blurb; a Source /
/// Established / Governor card; and "Places to See".
class CountyDetailScreen extends StatelessWidget {
  const CountyDetailScreen({
    super.key,
    required this.countyCode,
    required this.actions,
  });

  final int countyCode;
  final DiscoverDetailActions actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: DetailAsyncBody<CountyDetailData>(
          load: () => actions.countyDetail(countyCode),
          errorMessage: "Couldn't load this county.",
          builder: (context, data) =>
              _CountyDetailBody(data: data, actions: actions),
        ),
      ),
    );
  }
}

class _CountyDetailBody extends StatelessWidget {
  const _CountyDetailBody({required this.data, required this.actions});

  final CountyDetailData data;
  final DiscoverDetailActions actions;

  @override
  Widget build(BuildContext context) {
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
              Text(data.aboutBlurb, style: AppTextStyles.listItemSubtitle),
              const SizedBox(height: 11),
              DetailFactCard(
                facts: [
                  ('Source', 'Kaunti47'),
                  ('Established', data.quickFacts.yearEstablished?.toString()),
                  ('Governor', data.quickFacts.governorName),
                ],
              ),
              const SizedBox(height: 15),
              const Text('Places to See', style: AppTextStyles.detailTitle),
              const SizedBox(height: 11),
              const Text(
                'Listings marked AD are paid placements. Places to see are '
                'never paid -- they come from KWS, UNESCO and OpenStreetMap.',
                style: AppTextStyles.listItemSubtitle,
              ),
              const SizedBox(height: 9),
              if (data.places.isEmpty)
                Text(
                  'No places on file yet for ${data.county.name}.',
                  style: AppTextStyles.listItemSubtitle,
                )
              else
                for (final place in data.places) ...[
                  PlacePhotoCard(
                    place: place,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlaceDetailScreen(
                          placeId: place.id,
                          actions: actions,
                        ),
                      ),
                    ),
                    onSavedChanged: (saved) => actions.setPlaceSaved(
                      countyCode: data.county.code,
                      placeId: place.id,
                      saved: saved,
                    ),
                  ),
                  const SizedBox(height: 9),
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
