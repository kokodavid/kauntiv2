import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/discover_detail_actions.dart';
import '../domain/place_detail.dart';
import 'detail_async_body.dart';
import 'place_detail_about_tile.dart';
import 'place_detail_bar.dart';
import 'place_detail_header.dart';

typedef PlaceDetailSectionBuilder =
    Widget Function(BuildContext context, PlaceDetailData place);

typedef OpenPlaceRoute =
    Future<void> Function(BuildContext context, PlaceDetailData place);

/// Place Detail: the photos, an expandable About tile and, for a place with
/// coordinates, the trip plan, scrolling together above a fixed bottom bar
/// with Start trip. A place without coordinates has a Get Route button.
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    required this.actions,
    this.onGetRoute,
    this.gettingThere,
    this.startButton,
  });

  final String placeId;
  final DiscoverDetailActions actions;
  final OpenPlaceRoute? onGetRoute;

  /// The trip plan, supplied by app/ (features compose there, not
  /// here). Only built for places with coordinates.
  final PlaceDetailSectionBuilder? gettingThere;

  /// The bottom bar's main button while [gettingThere] is shown: the trip
  /// builder's own "Start trip".
  final PlaceDetailSectionBuilder? startButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: DetailAsyncBody<PlaceDetailData>(
          load: () => actions.placeDetail(placeId),
          errorMessage: "Couldn't load this place.",
          builder: (context, data) => _PlaceDetailBody(
            data: data,
            actions: actions,
            onGetRoute: onGetRoute,
            gettingThere: gettingThere,
            startButton: startButton,
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
    this.gettingThere,
    this.startButton,
  });

  final PlaceDetailData data;
  final DiscoverDetailActions actions;
  final OpenPlaceRoute? onGetRoute;
  final PlaceDetailSectionBuilder? gettingThere;
  final PlaceDetailSectionBuilder? startButton;

  @override
  State<_PlaceDetailBody> createState() => _PlaceDetailBodyState();
}

class _PlaceDetailBodyState extends State<_PlaceDetailBody> {
  bool _openingRoute = false;

  bool get _planned =>
      widget.gettingThere != null &&
      widget.startButton != null &&
      widget.data.hasCoordinates;

  Future<void> _getRoute(BuildContext context) async {
    if (_openingRoute) return;
    setState(() => _openingRoute = true);
    try {
      final open = widget.onGetRoute;
      if (open != null) {
        await open(context, widget.data);
      } else {
        final opened = await widget.actions.openDirections(widget.data);
        if (!opened && context.mounted) _say(context, "Couldn't open directions.");
      }
    } on Object {
      if (context.mounted) _say(context, "Couldn't open directions.");
    } finally {
      if (mounted) setState(() => _openingRoute = false);
    }
  }

  void _say(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

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
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlaceDetailAboutTile(
                              description: data.description,
                            ),
                            if (_planned) ...[
                              const SizedBox(height: 22),
                              widget.gettingThere!(context, data),
                            ],
                          ],
                        ),
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
          primary: _planned
              ? widget.startButton!(context, data)
              : _GetRouteButton(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
