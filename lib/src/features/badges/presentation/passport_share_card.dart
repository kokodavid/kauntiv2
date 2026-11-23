import 'package:flutter/material.dart';

import '../../../core/widgets/app_share_watermark.dart';
import '../../../design/app_colors.dart';
import '../domain/passport_book.dart';
import '../domain/passport_county.dart';
import '../domain/passport_level.dart';
import 'passport_dates.dart';
import 'passport_kenya_map.dart';
import 'passport_level_bar.dart';
import 'passport_medallion.dart';
import 'passport_palette.dart';
import 'passport_stamp_art.dart';
import 'passport_text.dart';
import 'passport_traveller_card.dart';

part 'passport_share_card_bits.dart';
part 'passport_share_card_paper.dart';
part 'passport_share_card_photo.dart';

/// The two looks a Passport share image comes in.
enum PassportShareStyle {
  /// The paper look of the Traveller card, with the mountain line art.
  passport,

  /// The map and count over a photo the traveller picked.
  photo,
}

/// The shareable Passport image (Claude-Design "Passport Share Card"):
/// the traveller, the count, a legend, the Kenya map, the 47-segment bar
/// and the latest stamp. Story size (9:16).
///
/// The @username is always drawn, whatever [showName] says: it ties a
/// shared Passport to its owner, so nobody can pass someone else's off as
/// their own. [showName] only hides the display name.
///
/// Pure layout from resolved data; rasterizing it is `captureShareCard`'s
/// job. Lays out at its logical [width] x [height] only.
class PassportShareCard extends StatelessWidget {
  const PassportShareCard({
    super.key,
    required this.style,
    required this.book,
    required this.username,
    this.holderName,
    this.showName = true,
    this.showArt = true,
    this.photo,
    this.width = 360,
    this.height = 640,
  });

  final PassportShareStyle style;
  final PassportBook book;

  /// The handle without the "@".
  final String username;
  final String? holderName;
  final bool showName;

  /// Passport style only: the mountain line art along the bottom.
  final bool showArt;

  /// Photo style only; null draws a plain dark background.
  final ImageProvider? photo;
  final double width;
  final double height;

  /// Stories safe zone: clear of the strips where Instagram and WhatsApp
  /// draw their own UI (same as the Trip share card).
  static const padding = EdgeInsets.fromLTRB(20, 72, 20, 104);

  /// The name to draw, or null when it's hidden or empty.
  String? get _name {
    final name = holderName?.trim();
    return showName && name != null && name.isNotEmpty ? name : null;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ClipRect(
      child: switch (style) {
        PassportShareStyle.passport => _PaperCard(
          book: book,
          username: username,
          name: _name,
          showArt: showArt,
        ),
        PassportShareStyle.photo => _PhotoCard(
          book: book,
          username: username,
          name: _name,
          photo: photo,
        ),
      },
    ),
  );
}
