import 'dart:async';

import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';
import 'map_home_county_map_painter.dart';

/// Gently fades [child] in and out while Map Home's data is loading.
class MapHomeSkeletonPulse extends StatefulWidget {
  const MapHomeSkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<MapHomeSkeletonPulse> createState() => _MapHomeSkeletonPulseState();
}

class _MapHomeSkeletonPulseState extends State<MapHomeSkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _opacity = Tween<double>(
      begin: 0.45,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    unawaited(_controller.repeat(reverse: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// Lays out [child] invisibly (so the placeholder takes exactly the space
/// the real content will) and shows a pulsing block in its place.
class MapHomeSkeletonMask extends StatelessWidget {
  const MapHomeSkeletonMask({super.key, required this.child, this.radius = 6});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(opacity: 0, child: child),
        Positioned.fill(
          child: MapHomeSkeletonPulse(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.trackInactive,
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A plain pulsing placeholder block of a fixed size.
class MapHomeSkeletonBlock extends StatelessWidget {
  const MapHomeSkeletonBlock({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return MapHomeSkeletonMask(
      radius: radius,
      child: SizedBox(width: width, height: height),
    );
  }
}

/// Kenya's county outlines, uncoloured and pulsing, in exactly the position
/// [MapHomeCountyMap] will draw the real map. Counties fill in with their
/// badge colours when the board loads.
class MapHomeLoadingMap extends StatelessWidget {
  const MapHomeLoadingMap({super.key});

  static final _neutralBadges = [
    for (final county in CountyPaths.all)
      MapHomeCountyBadge(county: county, state: MapHomeCountyBadgeState.locked),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading your county map',
      child: Align(
        alignment: Alignment.topCenter,
        child: AspectRatio(
          aspectRatio: CountyPaths.viewBoxWidth / CountyPaths.viewBoxHeight,
          child: MapHomeSkeletonPulse(
            child: CustomPaint(
              painter: MapHomeCountiesPainter(badges: _neutralBadges),
            ),
          ),
        ),
      ),
    );
  }
}
