import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/map_home_board_loader.dart';
import '../domain/map_home_models.dart';
import 'map_home_board.dart';

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({
    super.key,
    this.homeCounty,
    this.loader = const MapHomeBoardLoader(),
  });

  final CountyPath? homeCounty;
  final MapHomeBoardLoader loader;

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
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<MapHomeBoardData>(
          future: _board,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _MapHomeLoadMessage(
                title: "Couldn't load your map.",
                body: 'Check your connection and try again.',
              );
            }
            // Null while loading: the board renders its own placeholders.
            return MapHomeBoard(data: snapshot.data);
          },
        ),
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
            Text(body, textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
          ],
        ),
      ),
    );
  }
}
