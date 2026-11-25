import 'package:flutter/material.dart';

/// A county's ink stamp (`assets/stamps/`), shared by the Passport and
/// Profile. Inked when the county is stamped; otherwise greyed out at
/// [greyOpacity]. Counties without artwork aren't drawn: check [has] first.
class CountyStampImage extends StatelessWidget {
  const CountyStampImage({
    super.key,
    required this.countyName,
    required this.extent,
    this.greyOpacity,
  });

  final String countyName;

  /// The square the stamp fits inside (it keeps its own proportions).
  final double extent;

  /// Null: full ink. Otherwise the stamp is greyed and drawn this opaque.
  final double? greyOpacity;

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

  static bool has(String countyName) => _available.contains(_slug(countyName));

  /// The stamp's asset path (only meaningful when [has] is true).
  static String assetFor(String countyName) =>
      'assets/stamps/${_slug(countyName)}.webp';

  static const _grey = ColorFilter.matrix([
    0.33, 0.33, 0.33, 0, 0, //
    0.33, 0.33, 0.33, 0, 0,
    0.33, 0.33, 0.33, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    Widget art = Image.asset(
      assetFor(countyName),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: '$countyName stamp',
    );
    final grey = greyOpacity;
    if (grey != null) {
      art = Opacity(
        opacity: grey,
        child: ColorFiltered(colorFilter: _grey, child: art),
      );
    }
    return SizedBox.square(
      dimension: extent,
      child: Center(child: art),
    );
  }
}
