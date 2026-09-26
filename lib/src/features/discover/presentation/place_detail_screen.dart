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

typedef OpenPlaceRoute = Future<void> Function(
  BuildContext context,
  PlaceDetailData place,
);

/// Place Detail (v2 Figma node 235:7353, ported from v1): photo carousel
/// with back button and category pill, title, description, a Source /
/// Type card, and a floating Get Route / share / save bar.
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    required this.actions,
    this.onGetRoute,
  });

  final String placeId;
  final DiscoverDetailActions actions;
  final OpenPlaceRoute? onGetRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: DetailAsyncBody<PlaceDetailData>(
          load: () => actions.placeDetail(placeId),
          errorMessage: "Couldn't load this place.",
          builder: (context, data) =>
              _PlaceDetailBody(
                data: data,
                actions: actions,
                onGetRoute: onGetRoute,
              ),
        ),
      ),
    );
  }
}

class _PlaceDetailBody extends StatefulWidget {
  const _PlaceDetailBody({
    required this.data,
    required this.actions,
    this.onGetRoute,
  });

  final PlaceDetailData data;
  final DiscoverDetailActions actions;
  final OpenPlaceRoute? onGetRoute;

  @override
  State<_PlaceDetailBody> createState() => _PlaceDetailBodyState();
}

class _PlaceDetailBodyState extends State<_PlaceDetailBody> {
  bool _openingRoute = false;

  Future<void> _getRoute(BuildContext context) async {
    if (_openingRoute) return;
    setState(() => _openingRoute = true);
    try {
      final open = widget.onGetRoute;
      if (open != null) {
        await open(context, widget.data);
      } else {
        final opened = await widget.actions.openDirections(widget.data);
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't open directions.")),
          );
        }
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open directions.")),
        );
      }
    } finally {
      if (mounted) setState(() => _openingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final actions = widget.actions;
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
                      style: AppTextStyles.detailBody,
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
                    onPressed: _openingRoute
                        ? null
                        : () => unawaited(_getRoute(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.accentForeground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _openingRoute
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
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
                  Text(category.label, style: AppTextStyles.detailBody),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
