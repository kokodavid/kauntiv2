import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../counties/county_paths.dart';
import '../../design/app_colors.dart';
import '../../widgets/app_county_shape.dart';
import '../../widgets/app_svg_path.dart';
import '../design/app_type_scale.dart';

part 'county_badge_medallion_painters.dart';

/// A county badge (Figma "Badge", no stars): a glossy disc with the county
/// name across the top and its silhouette in white. Blue once earned,
/// the map's "passed" yellow when only passed through, grey otherwise.
/// Drawn at any [size]; the design is 74 px. With [back] it's the coin's
/// reverse: the same disc with the Kaunti47 mark.
///
/// Lives in `widgets/` rather than the Badges feature because Journeys'
/// "Entered county" timeline card (`journey_county_moment_card.dart`)
/// reuses it too - shared by two features, so it belongs in `core`, not
/// either one (architecture.md §1).
class CountyBadgeMedallion extends StatelessWidget {
  const CountyBadgeMedallion({
    super.key,
    required this.county,
    required this.earned,
    this.passedThrough = false,
    this.size = 74,
    this.back = false,
  });

  final CountyPath county;
  final bool earned;

  /// Passed through but not earned: drawn in the map's "passed" colour.
  /// Ignored once [earned].
  final bool passedThrough;
  final double size;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final unit = size / 74;
    if (back) return _back(unit);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DiscPainter(
                earned: earned,
                passedThrough: passedThrough,
              ),
            ),
          ),
          Positioned(
            left: 6 * unit,
            right: 6 * unit,
            top: 12.3 * unit,
            child: Text(
              county.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypeScale.family,
                fontWeight: FontWeight.w600,
                fontSize: 7.7 * unit,
                height: 1.2,
                letterSpacing: 0.2 * unit,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: const Color(0x1F000000),
                    offset: Offset(0, 0.77 * unit),
                    blurRadius: 4.6 * unit,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 17 * unit,
            right: 17 * unit,
            top: 25 * unit,
            bottom: 17 * unit,
            child: AppCountyShape(county: county, fill: Colors.white),
          ),
        ],
      ),
    );
  }
}

extension on CountyBadgeMedallion {
  /// The reverse: Kenya's map with this county picked out in white, and
  /// the Kaunti47 mark under it.
  Widget _back(double unit) => SizedBox.square(
    dimension: size,
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
              painter: _DiscPainter(
                earned: earned,
                passedThrough: passedThrough,
              ),
            ),
        ),
        Positioned(
          left: 18 * unit,
          right: 18 * unit,
          top: 12 * unit,
          bottom: 20 * unit,
          child: CustomPaint(painter: _KenyaPainter(county.code)),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10 * unit,
          child: Text(
            'KAUNTI47',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypeScale.family,
              fontWeight: FontWeight.w600,
              fontSize: 6 * unit,
              letterSpacing: 1 * unit,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}
