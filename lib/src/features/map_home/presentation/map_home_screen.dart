import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/connectivity_state.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../core/services/offline_saved_at.dart';
import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/map_home_board_loader.dart';
import '../domain/map_home_models.dart';
import 'map_home_board.dart';
import 'map_home_board_sheet.dart' show defaultRecordTripCardHeight;
import 'map_home_links.dart';

class MapHomeScreen extends ConsumerStatefulWidget {
  const MapHomeScreen({
    super.key,
    this.homeCounty,
    this.loader = const MapHomeBoardLoader(),
    this.mapboxAccessToken = '',
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
    this.onPlaceRoute,
    this.onPromotedPlaceRoute,
    this.onSeeAllUnclaimed,
    this.onOpenProfile,
    this.isTripRecording = false,
    this.onStartTrip,
    this.tripsNear,
    this.savedPlans,
    this.recordTripCard,
    this.recordTripCardHeight = defaultRecordTripCardHeight,
    this.topCard,
  });

  final CountyPath? homeCounty;

  /// A Trip is recording; the sheet puts the nearest county first.
  final bool isTripRecording;

  /// Starts a Trip, or null when Trips are not available.
  final VoidCallback? onStartTrip;

  /// The public trips row, when that feature is on.
  final Widget? tripsNear;
  final Widget? savedPlans;

  /// The one-tap Record a Trip card, passed only while the phone is moving.
  final Widget? recordTripCard;
  final double recordTripCardHeight;

  /// A card shown above Home's sections, supplied by `app/` (null hides).
  final Widget? topCard;
  final MapHomeBoardLoader loader;

  /// Empty: Home shows the drawn county map only.
  final String mapboxAccessToken;

  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;
  final OpenDirections? onRoute;
  final OpenPlaceDirections? onPlaceRoute;
  final OpenPromotedPlaceDirections? onPromotedPlaceRoute;
  final OpenAllUnclaimed? onSeeAllUnclaimed;
  final VoidCallback? onOpenProfile;

  @override
  ConsumerState<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends ConsumerState<MapHomeScreen>
    with WidgetsBindingObserver {
  late Future<MapHomeBoardData> _board;
  bool _offline = false;
  bool _retrying = false;
  Timer? _autoRetry;

  /// While Home runs from its saved copy, it quietly tries the server again
  /// this often (and on resume) and swaps the live board in when it works.
  static const _autoRetryEvery = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _board = widget.loader.loadBoard(homeCounty: widget.homeCounty);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRetry?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _offline) unawaited(_retry());
  }

  void _trackOffline(MapHomeBoardData? data) {
    final offline = data?.isOffline ?? false;
    // Only while Home is the tab on screen: the banner switches to its Home
    // form (saved time and Retry) there, and stays plain on other tabs.
    final active = TickerMode.valuesOf(context).enabled;
    final savedAt = offline && active ? data?.savedAt : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(offlineSavedAtProvider.notifier).set(savedAt);
    });
    if (offline == _offline) return;
    _offline = offline;
    _autoRetry?.cancel();
    _autoRetry = offline
        ? Timer.periodic(_autoRetryEvery, (_) => unawaited(_retry()))
        : null;
  }

  /// Asks the server again; keeps the saved copy on screen until the live
  /// board arrives, so there is no flash.
  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      final live = await widget.loader.loadBoard(homeCounty: widget.homeCounty);
      if (!mounted || live.isOffline) return;
      setState(() => _board = Future.value(live));
    } on Object {
      // Still offline; the strip stays.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The connection came back: swap the live board in.
    ref.listen(connectivityProvider.select((s) => s.status), (prev, next) {
      if (_offline &&
          (next == ConnectivityStatus.reconnecting ||
              next == ConnectivityStatus.upToDate)) {
        unawaited(_retry());
      }
    });
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      // The board handles safe areas itself so the real map can run
      // edge to edge under the status bar.
      body: FutureBuilder<MapHomeBoardData>(
        future: _board,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SafeArea(
              child: _MapHomeLoadMessage(
                title: "Couldn't load your map.",
                body: 'Check your connection and try again.',
              ),
            );
          }
          _trackOffline(snapshot.data);
          // Null while loading: the board renders its own placeholders.
          return MapHomeBoard(
            data: snapshot.data,
            loadMapPlaces: widget.loader.loadMapPlaces,
            // Offline: no token, so Home stays on the drawn county map.
            mapboxAccessToken: snapshot.data?.isOffline == true
                ? ''
                : widget.mapboxAccessToken,
            onOpenCounty: widget.onOpenCounty,
            onOpenPlace: widget.onOpenPlace,
            onRoute: widget.onRoute,
            onPlaceRoute: widget.onPlaceRoute,
            onPromotedPlaceRoute: widget.onPromotedPlaceRoute,
            onSeeAllUnclaimed: widget.onSeeAllUnclaimed,
            onOpenProfile: widget.onOpenProfile,
            isTripRecording: widget.isTripRecording,
            onStartTrip: widget.onStartTrip,
            tripsNear: widget.tripsNear,
            savedPlans: widget.savedPlans,
            recordTripCard: widget.recordTripCard,
            recordTripCardHeight: widget.recordTripCardHeight,
            topCard: widget.topCard,
          );
        },
      ),
    );
  }
}

class _MapHomeLoadMessage extends StatelessWidget {
  const _MapHomeLoadMessage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingForeground,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}
