import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/map_home_board_loader.dart';
import '../domain/map_home_models.dart';
import 'map_home_board.dart';
import 'map_home_links.dart';

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({
    super.key,
    this.homeCounty,
    this.loader = const MapHomeBoardLoader(),
    this.mapboxAccessToken = '',
    this.onOpenCounty,
    this.onOpenPlace,
    this.onRoute,
  });

  final CountyPath? homeCounty;
  final MapHomeBoardLoader loader;

  /// Empty: Home shows the drawn county map only.
  final String mapboxAccessToken;

  final OpenCountyDetail? onOpenCounty;
  final OpenPlaceDetail? onOpenPlace;
  final OpenDirections? onRoute;

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  late final Future<MapHomeBoardData> _board;

  @override
  void initState() {
    super.initState();
    _board = widget.loader.loadBoard(homeCounty: widget.homeCounty);
  }

  @override
  Widget build(BuildContext context) {
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
          // Null while loading: the board renders its own placeholders.
          return MapHomeBoard(
            data: snapshot.data,
            loadMapPlaces: widget.loader.loadMapPlaces,
            mapboxAccessToken: widget.mapboxAccessToken,
            onOpenCounty: widget.onOpenCounty,
            onOpenPlace: widget.onOpenPlace,
            onRoute: widget.onRoute,
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
