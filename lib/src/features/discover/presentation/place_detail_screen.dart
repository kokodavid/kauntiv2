import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/discover_detail_actions.dart';
import '../domain/place_category.dart';
import '../domain/place_detail.dart';
import 'detail_async_body.dart';
import 'detail_photo_carousel.dart';
import 'detail_widgets.dart';
import 'place_category_style.dart';

/// Place Detail (v2 Figma node 235:7353, ported from v1): photo carousel
/// with back button and category pill, title, description, a Source /
/// Type card, and a floating Get Route / share / save bar.
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    required this.actions,
  });

  final String placeId;
  final DiscoverDetailActions actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: DetailAsyncBody<PlaceDetailData>(
          load: () => actions.placeDetail(placeId),
          errorMessage: "Couldn't load this place.",
          builder: (context, data) =>
              _PlaceDetailBody(data: data, actions: actions),
        ),
      ),
    );
  }
}

class _PlaceDetailBody extends StatelessWidget {
  const _PlaceDetailBody({required this.data, required this.actions});

  final PlaceDetailData data;
  final DiscoverDetailActions actions;

  Future<void> _getRoute(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await actions.openDirections(data);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't open directions.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(7, 8, 7, 110),
            children: [
              AspectRatio(
                aspectRatio: 382 / 528,
                child: DetailPhotoCarousel(
                  images: data.images,
                  overlay: _PlacePhotoChrome(category: data.category),
                ),
              ),
              const SizedBox(height: 19),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, style: AppTextStyles.detailTitle),
                    const SizedBox(height: 11),
                    Text(
                      data.description.isEmpty
                          ? 'No description on file yet for this place.'
                          : data.description,
                      style: AppTextStyles.listItemSubtitle,
                    ),
                    const SizedBox(height: 11),
                    DetailFactCard(
                      facts: [
                        ('Source', data.source),
                        ('Type', data.category.label),
                        // v1's third fact is Distance; it returns once v2
                        // has a foreground location read.
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => unawaited(_getRoute(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.accentForeground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Get Route',
                      style: AppTextStyles.buttonLabel,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DetailGlassButton(
                icon: Icons.ios_share,
                tooltip: 'Share',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing is coming soon.')),
                ),
              ),
              const SizedBox(width: 8),
              DetailSaveButton(
                saved: data.saved,
                onChanged: (saved) => actions.setPlaceSaved(
                  countyCode: data.county.code,
                  placeId: data.id,
                  saved: saved,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlacePhotoChrome extends StatelessWidget {
  const _PlacePhotoChrome({required this.category});

  final PlaceCategory category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailBackButton(onPressed: () => Navigator.of(context).maybePop()),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.backButtonBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: category.dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(category.label, style: AppTextStyles.listItemSubtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
