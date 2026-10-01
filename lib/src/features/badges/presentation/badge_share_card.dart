import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../map_home/domain/county_badge_state.dart';
import '../domain/badge_collection.dart';
import 'badge_grid_cell.dart';

/// The badge as a card: large badge in its depth ring, the county, and a
/// line about it. Shown at the top of the badge sheet and, for earned
/// badges, captured as the image to share. It carries no location or
/// dates, only the badge and the tally.
class BadgeShareCard extends StatelessWidget {
  const BadgeShareCard({
    super.key,
    required this.badge,
    required this.claimed,
    required this.total,
    this.coinBuilder,
  });

  final CountyBadge badge;

  /// The badge inside the ring, e.g. the spinning coin.
  final Widget Function(double size)? coinBuilder;
  final int claimed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final earned = badge.isEarned;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: earned
              ? const [Color(0xFFE6F3FF), Colors.white]
              : const [AppColors.lockedFill, Colors.white],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 128,
            child: BadgeGridCell(badge: badge, coinBuilder: coinBuilder),
          ),
          const SizedBox(height: 14),
          Text(
            '${badge.county.name} County',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              height: 28 / 20,
              color: AppColors.foreground,
            ),
          ),
          Text(
            earned
                ? '${badge.depth.label} · $claimed of $total counties'
                : _statusLine(badge),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypeScale.family,
              fontSize: 13,
              height: 20 / 13,
              color: AppColors.mutedForeground,
            ),
          ),
          if (earned) ...[
            const SizedBox(height: 10),
            const Text(
              'KAUNTI47',
              style: TextStyle(
                fontFamily: AppTypeScale.family,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 2,
                color: AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLine(CountyBadge badge) => switch (badge.state) {
    CountyBadgeState.pending => 'Pending: confirms once your visit syncs',
    CountyBadgeState.passedThrough => 'Passed through, not yet earned',
    _ => 'Not yet earned',
  };

  /// Renders the card inside [boundaryKey]'s RepaintBoundary to a PNG.
  static Future<Uint8List?> capture(GlobalKey boundaryKey) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }
}
