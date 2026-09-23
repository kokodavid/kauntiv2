import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../application/map_home_board_loader.dart';
import '../domain/map_home_models.dart';
import 'map_home_board.dart';

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key, this.homeCounty});

  final CountyPath? homeCounty;

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  late final MapHomeBoardData _board;

  @override
  void initState() {
    super.initState();
    _board = const MapHomeBoardLoader().loadBoard(
      homeCounty: widget.homeCounty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(bottom: false, child: MapHomeBoard(data: _board)),
    );
  }
}
