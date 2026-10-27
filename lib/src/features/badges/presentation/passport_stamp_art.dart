import 'package:flutter/material.dart';

import '../domain/passport_county.dart';
import '../domain/passport_level.dart';
import 'passport_palette.dart';

/// The ink stamp for a county, where one has been drawn. Counties without
/// artwork yet keep their medallion; add a file to `assets/stamps/` and its
/// slug here to switch one over.
class PassportStampArt extends StatelessWidget {
  const PassportStampArt({
    super.key,
    required this.county,
    required this.extent,
  });

  final PassportCounty county;

  /// The square the stamp fits inside (it keeps its own proportions).
  final double extent;

  /// Counties with a finished stamp, by slug (lower case, letters only).
  static const _available = {
    // Central
    'kiambu',
    'kirinyaga',
    'muranga',
    'nyandarua',
    'nyeri',
    // Coast
    'kilifi',
    'kwale',
    'lamu',
    'mombasa',
    'tanariver',
    'taitataveta',
    // Eastern
    'embu',
    'kitui',
    'machakos',
    'makueni',
    'isiolo',
    'marsabit',
    'meru',
    'tharakanithi',
    // Nairobi
    'nairobi',
    // North Eastern
    'garissa',
    'wajir',
    'mandera',
    // Nyanza
    'homabay',
    'kisii',
    'kisumu',
    'migori',
    'nyamira',
    'siaya',
    // Rift Valley
    'baringo',
    'bomet',
    'elgeyomarakwet',
    'kajiado',
    'nandi',
    'nakuru',
    'laikipia',
    'kericho',
    'turkana',
    'transnzoia',
    'samburu',
    'narok',
    'uasingishu',
    'westpokot',
    // Western
    'busia',
    'kakamega',
    'vihiga',
    'bungoma',
  };

  static String _slug(String name) =>
      name.toLowerCase().replaceAll(RegExp('[^a-z]'), '');

  static bool has(PassportCounty county) =>
      _available.contains(_slug(county.name));

  /// Greys the ink out, for a county not stamped yet.
  static const _grey = ColorFilter.matrix([
    0.33, 0.33, 0.33, 0, 0, //
    0.33, 0.33, 0.33, 0, 0,
    0.33, 0.33, 0.33, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final level = county.level;
    final stamped = level.index >= PassportLevel.explored.index;
    Widget art = Image.asset(
      'assets/stamps/${_slug(county.name)}.webp',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: '${county.name} stamp',
    );
    if (!stamped) {
      art = Opacity(
        opacity: level == PassportLevel.none ? 0.22 : 0.45,
        child: ColorFiltered(colorFilter: _grey, child: art),
      );
    }
    return SizedBox.square(
      dimension: extent,
      child: Center(child: art),
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
