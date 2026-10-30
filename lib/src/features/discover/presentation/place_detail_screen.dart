import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/discover_detail_actions.dart';
import '../domain/place_detail.dart';
import 'detail_async_body.dart';
import 'explore_ad_slot.dart';
import 'place_detail_about_tile.dart';
import 'place_detail_bar.dart';
import 'place_detail_header.dart';

typedef PlaceDetailSectionBuilder =
    Widget Function(BuildContext context, PlaceDetailData place);

typedef OpenPlaceRoute =
    Future<void> Function(BuildContext context, PlaceDetailData place);

/// Place Detail: the photos and an expandable About tile, scrolling together
/// above a fixed bottom bar with Get Route, Share and Save.
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    required this.actions,
    this.onGetRoute,
    this.photos,
    this.checkIn,
    this.addToTrip,
  });

  final String placeId;
  final DiscoverDetailActions actions;
  final OpenPlaceRoute? onGetRoute;

  /// The Photos section (strip, add tile, status chip), supplied by app/
  /// (features compose there).
  final PlaceDetailSectionBuilder? photos;

  /// The check-in card ("I'm here"), supplied by app/. Shown for a place with
  /// coordinates, above the photos.
  final PlaceDetailSectionBuilder? checkIn;

  /// "Add to trip", supplied by app/. Shown under the photos for every place.
  final PlaceDetailSectionBuilder? addToTrip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: DetailAsyncBody<PlaceDetailData>(
          load: () => actions.placeDetail(placeId),
          builder: (context, data) => _PlaceDetailBody(
            data: data,
            actions: actions,
            onGetRoute: onGetRoute,
            photos: photos,
            checkIn: checkIn,
            addToTrip: addToTrip,
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
    this.photos,
    this.checkIn,
    this.addToTrip,
  });

  final PlaceDetailData data;
  final DiscoverDetailActions actions;
  final OpenPlaceRoute? onGetRoute;
  final PlaceDetailSectionBuilder? photos;
  final PlaceDetailSectionBuilder? checkIn;
  final PlaceDetailSectionBuilder? addToTrip;

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
          _say(context, "Couldn't open directions.");
        }
      }
    } on Object {
      if (context.mounted) _say(context, "Couldn't open directions.");
    } finally {
      if (mounted) setState(() => _openingRoute = false);
    }
  }

  /// The place's story: description and every photo.
  Widget _about(BuildContext context, PlaceDetailData data) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PlaceDetailAboutTile(description: data.description),
      // One ad under the description, clear of the check-in card and the
      // Start trip bar. Renders nothing unless ads are on for this user.
      const SizedBox(height: 12),
      const ExploreAdSlot(),
      if (widget.photos != null) ...[
        const SizedBox(height: 8),
        widget.photos!(context, data),
      ],
    ],
  );

  void _say(BuildContext context, String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlaceDetailHeader(
                        images: data.images,
                        title: data.title,
                        countyName: '${data.county.name} County',
                        category: data.category,
                        credits: data.imageCredits,
                      ),
                      if (widget.addToTrip != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: widget.addToTrip!(context, data),
                        ),
                      if (widget.checkIn != null && data.hasCoordinates)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: widget.checkIn!(context, data),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _about(context, data),
                      ),
                    ],
                  ),
                ),
              ),
              // Stays put while the page scrolls under it.
              Positioned(
                left: 24,
                top: 20,
                child: AppBackButton(
                  size: 44,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
        PlaceDetailBar(
          primary: _GetRouteButton(
            busy: _openingRoute,
            onPressed: () => unawaited(_getRoute(context)),
          ),
          saved: data.saved,
          onSavedChanged: (saved) => widget.actions.setPlaceSaved(
            countyCode: data.county.code,
            placeId: data.id,
            saved: saved,
          ),
          onShare: () => _say(context, 'Sharing is coming soon.'),
        ),
      ],
    );
  }
}

class _GetRouteButton extends StatelessWidget {
  const _GetRouteButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentForeground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: busy
            ? const AppProgressIndicator(
                color: AppColors.accentForeground,
                radius: 9,
              )
            : const Text('Get Route', style: AppTextStyles.buttonLabel),
      ),
    );
  }
}
