import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../core/widgets/place_detail_bar_button.dart';
import '../../../design/app_colors.dart';
import '../application/discover_detail_actions.dart';
import '../domain/place_detail.dart';
import 'detail_async_body.dart';
import 'explore_ad_slot.dart';
import 'place_detail_about_section.dart';
import 'place_detail_action_bar.dart';
import 'place_detail_header.dart';
import 'place_detail_header_actions.dart';

typedef PlaceDetailSectionBuilder =
    Widget Function(BuildContext context, PlaceDetailData place);

typedef OpenPlaceRoute =
    Future<void> Function(BuildContext context, PlaceDetailData place);

/// Place Detail: header, then one floating action bar for the whole
/// page's primary actions, then Photos and an always-open About -- no
/// docked bottom bar, no tap-to-expand tile. The old layout stacked
/// "Add to trip" and the check-in card full width above a collapsible
/// About tile, with Photos last and a docked Get Route bar; this reads
/// top to bottom with the bar floating over the content, the way
/// `AppBottomNav` floats over the tabs.
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    required this.actions,
    this.onGetRoute,
    this.photos,
    this.checkIn,
    this.addToTrip,
    this.addPhoto,
  });

  final String placeId;
  final DiscoverDetailActions actions;
  final OpenPlaceRoute? onGetRoute;

  /// The Photos section (strip, "See all"), supplied by app/ (features
  /// compose there). Shown above About.
  final PlaceDetailSectionBuilder? photos;

  /// The check-in bar item ("I'm here"), supplied by app/. Shown in the
  /// floating action bar for a place with coordinates.
  final PlaceDetailSectionBuilder? checkIn;

  /// The "Add to trip" bar item, supplied by app/. Shown in the floating
  /// action bar for every place; app/ passes null while the trip planner
  /// is off, and the bar then leaves it out.
  final PlaceDetailSectionBuilder? addToTrip;

  /// The "Add photo" bar item, supplied by app/. Shown in the floating
  /// action bar for a place that takes photos.
  final PlaceDetailSectionBuilder? addPhoto;

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
            addPhoto: addPhoto,
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
    this.addPhoto,
  });

  final PlaceDetailData data;
  final DiscoverDetailActions actions;
  final OpenPlaceRoute? onGetRoute;
  final PlaceDetailSectionBuilder? photos;
  final PlaceDetailSectionBuilder? checkIn;
  final PlaceDetailSectionBuilder? addToTrip;
  final PlaceDetailSectionBuilder? addPhoto;

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
          _toastError(context, "Couldn't open directions.");
        }
      }
    } on Object {
      if (context.mounted) _toastError(context, "Couldn't open directions.");
    } finally {
      if (mounted) setState(() => _openingRoute = false);
    }
  }

  void _toastError(BuildContext context, String message) =>
      showAppToast(context, variant: AppToastVariant.error, title: message);

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 8,
              bottom: AppBottomNav.clearance(context) + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlaceDetailHeader(
                  images: data.images,
                  title: data.title,
                  countyName: '${data.county.name} County',
                  credits: data.imageCredits,
                ),
                if (widget.photos != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: widget.photos!(context, data),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                  child: PlaceDetailAboutSection(
                    description: data.description,
                    category: data.category,
                    countyName: '${data.county.name} County',
                  ),
                ),
                const SizedBox(height: 12),
                // Renders nothing unless ads are on for this user.
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ExploreAdSlot(),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 24,
          top: 20,
          child: AppBackButton(
            size: 44,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        Positioned(
          right: 24,
          top: 20,
          child: PlaceDetailHeaderActions(
            saved: data.saved,
            onSavedChanged: (saved) => widget.actions.setPlaceSaved(
              countyCode: data.county.code,
              placeId: data.id,
              saved: saved,
            ),
          ),
        ),
        PlaceDetailActionBar(
          addToTrip: widget.addToTrip?.call(context, data),
          checkIn: widget.checkIn != null && data.hasCoordinates
              ? widget.checkIn!(context, data)
              : null,
          addPhoto: widget.addPhoto?.call(context, data),
          route: PlaceDetailBarButton(
            icon: Icons.directions,
            label: 'Route',
            busy: _openingRoute,
            highlighted: true,
            onPressed: () => unawaited(_getRoute(context)),
          ),
        ),
      ],
    );
  }
}
