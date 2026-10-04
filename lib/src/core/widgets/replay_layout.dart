import 'package:flutter/material.dart';

/// The replay page shape: the map on top, a stat bar overlapping its bottom
/// edge, the story scrolling below, corner buttons over the map, and a
/// floating transport bar. Slots only; each replay supplies its own parts.
class ReplayLayout extends StatelessWidget {
  const ReplayLayout({
    super.key,
    required this.mapBuilder,
    required this.bodyBuilder,
    required this.statBar,
    required this.playbackBar,
    this.overlays = const [],
  });

  /// How much the stat bar overlaps the map's bottom edge.
  static const overlap = 32.0;

  /// Gets the height at the map's bottom that the stat bar covers, so the
  /// map can keep its logo and framing clear of it.
  final Widget Function(BuildContext context, double bottomInset) mapBuilder;

  /// The scrolling story. Its list should use the paddings so the first and
  /// last items clear the stat bar and the transport bar.
  final Widget Function(
    BuildContext context,
    double topPadding,
    double bottomPadding,
  )
  bodyBuilder;

  final Widget statBar;
  final Widget playbackBar;

  /// Buttons floating over the map; each positions itself.
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = (constraints.maxHeight * 0.42).clamp(260.0, 420.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: mapHeight,
              child: mapBuilder(context, overlap),
            ),
            Positioned.fill(
              top: mapHeight,
              child: bodyBuilder(context, overlap + 16, 104 + safeBottom),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: mapHeight - overlap,
              child: statBar,
            ),
            ...overlays,
            Positioned(
              left: 16,
              right: 16,
              bottom: 12 + safeBottom,
              child: playbackBar,
            ),
          ],
        );
      },
    );
  }
}
