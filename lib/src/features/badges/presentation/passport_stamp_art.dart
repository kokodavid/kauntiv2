import 'package:flutter/material.dart';

import '../../../core/widgets/county_stamp_image.dart';

import '../domain/passport_county.dart';
import '../domain/passport_level.dart';
import 'passport_palette.dart';

/// The ink stamp for a county, where one has been drawn. Counties without
/// artwork yet keep their medallion; add a file to `assets/stamps/` and its
/// slug to [CountyStampImage] to switch one over.
class PassportStampArt extends StatelessWidget {
  const PassportStampArt({
    super.key,
    required this.county,
    required this.extent,
  });

  final PassportCounty county;

  /// The square the stamp fits inside (it keeps its own proportions).
  final double extent;

  static bool has(PassportCounty county) => CountyStampImage.has(county.name);

  /// The stamp's asset path (only meaningful when [has] is true), so a
  /// caller can precache it before rendering an image off-screen.
  static String assetFor(PassportCounty county) =>
      CountyStampImage.assetFor(county.name);

  @override
  Widget build(BuildContext context) {
    final level = county.level;
    final stamped = level.index >= PassportLevel.explored.index;
    return CountyStampImage(
      countyName: county.name,
      extent: extent,
      // Greys the ink out, for a county not stamped yet.
      greyOpacity: stamped
          ? null
          : level == PassportLevel.none
          ? 0.22
          : 0.45,
    );
  }
}

/// Five dots, one per stamp step, filled in each step's colour as the county
/// reaches it. Stands in for the ring round the medallion under a stamp.
class PassportLevelDots extends StatelessWidget {
  const PassportLevelDots({super.key, required this.level});

  final PassportLevel level;

  static const _size = 7.0;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final step in PassportLevel.stamps) ...[
            if (step != PassportLevel.passedThrough) const SizedBox(width: 4),
            Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.isReachedAt(level) ? step.ring : PassportInk.track,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
