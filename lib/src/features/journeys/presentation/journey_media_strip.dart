import 'package:flutter/material.dart';

import '../domain/journey_media_capture.dart';

/// Opens [item] full screen over a black backdrop - shared by every
/// photo moment in the replay timeline.
void openJourneyPhoto(BuildContext context, JourneyMediaItem item) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _FullScreenPhoto(item: item),
    ),
  );
}

class _FullScreenPhoto extends StatelessWidget {
  const _FullScreenPhoto({required this.item});

  final JourneyMediaItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: InteractiveViewer(
              child: Image.network(
                item.url,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
