import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Rasterizes a [TripShareCard] (or any widget) to a PNG without ever
/// putting it on screen, by mounting it far outside the viewport through
/// an [OverlayEntry] rather than actually showing it to the user.
///
/// Used both to produce the history-card thumbnail PNG (Phase 5) and the
/// full-resolution image handed to the share sheet (Phase 6) - same
/// mechanism, different [card] size and [pixelRatio].
Future<Uint8List> captureTripShareCard({
  required BuildContext context,
  required Widget card,
  double pixelRatio = 3,
}) async {
  final key = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (context) => Transform.translate(
      // Off-screen, not invisible: Opacity(opacity: 0) would hit
      // RenderOpacity's zero-alpha fast path and skip painting
      // entirely, which would make toImage() capture a blank frame.
      // Moving it off-screen keeps a real paint happening.
      offset: const Offset(-4000, -4000),
      child: Material(
        type: MaterialType.transparency,
        // UnconstrainedBox, not a bare RepaintBoundary straight under
        // Material: an OverlayEntry's own box can hand its subtree
        // tight (or otherwise non-loose) constraints sized to the
        // overlay itself - e.g. close to the device's full screen -
        // and `card` (a plain SizedBox(width:, height:) internally)
        // gets clamped down into whatever box it's given, same failure
        // mode as the preview's Transform.scale wrapper had. The
        // captured PNG still "looked fine" for thumbnails, since the
        // history list always redisplays them through its own
        // fixed-size, fit:cover slot regardless of the file's real
        // pixel size - but the Save/Share output has no such slot to
        // hide it, which is what surfaced this: a full-bleed capture
        // with the overlay text reading tiny against it, not the
        // compact framed card from the preview. UnconstrainedBox gives
        // the RepaintBoundary (and `card` inside it) fully unconstrained
        // layout, so it always sizes itself to exactly `card`'s own
        // requested width/height, independent of whatever the overlay
        // happens to impose above it.
        child: UnconstrainedBox(
          child: RepaintBoundary(key: key, child: card),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    RenderRepaintBoundary? boundary;
    // A freshly-inserted overlay entry needs a few frames before its
    // RenderObject has a size - especially here, where the card's photo
    // (if any) still has to decode. The caller is expected to have
    // already called precacheImage() on it, but we still retry a few
    // times rather than assume a single frame is enough.
    for (var attempt = 0; attempt < 10; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      final found = key.currentContext?.findRenderObject();
      if (found is RenderRepaintBoundary && found.hasSize) {
        boundary = found;
        break;
      }
    }
    if (boundary == null) {
      throw StateError(
        'Trip share card never finished a paint pass to capture.',
      );
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Could not encode the Trip share card to PNG.');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}
