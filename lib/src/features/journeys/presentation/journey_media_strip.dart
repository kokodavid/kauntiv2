import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/app_network_image.dart';
import '../domain/journey_media_capture.dart';

/// Opens [item] full screen over a black backdrop - shared by every
/// photo moment in the replay timeline. [onDelete], when given, shows a
/// delete button that hands this photo's removal off to the caller (who
/// owns the confirm sheet and the actual delete - this widget only
/// knows to close itself once that comes back true).
void openJourneyPhoto(
  BuildContext context,
  JourneyMediaItem item, {
  Future<bool> Function(BuildContext context, JourneyMediaItem item)? onDelete,
}) {
  unawaited(
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FullScreenPhoto(item: item, onDelete: onDelete),
      ),
    ),
  );
}

class _FullScreenPhoto extends StatefulWidget {
  const _FullScreenPhoto({required this.item, this.onDelete});

  final JourneyMediaItem item;
  final Future<bool> Function(BuildContext context, JourneyMediaItem item)?
  onDelete;

  @override
  State<_FullScreenPhoto> createState() => _FullScreenPhotoState();
}

class _FullScreenPhotoState extends State<_FullScreenPhoto> {
  var _deleting = false;

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null || _deleting) return;
    setState(() => _deleting = true);
    bool removed;
    try {
      removed = await onDelete(context, widget.item);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
    if (removed && mounted) unawaited(Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image(
                    image: appNetworkImage(
                      widget.item.url,
                      cacheKey: widget.item.id,
                    ),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
              // A nested GestureDetector here wins the tap gesture arena
              // over the backdrop's tap-to-close ancestor, so tapping
              // either button acts on itself rather than also closing
              // the viewer underneath it.
              Positioned(
                top: 8,
                left: 8,
                child: _ViewerButton(
                  onTap: () => Navigator.of(context).maybePop(),
                  icon: Icons.close,
                ),
              ),
              if (widget.onDelete != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _ViewerButton(
                    onTap: _delete,
                    icon: Icons.delete_outline,
                    busy: _deleting,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the full-screen viewer's round corner buttons (close, delete).
class _ViewerButton extends StatelessWidget {
  const _ViewerButton({
    required this.onTap,
    required this.icon,
    this.busy = false,
  });

  final VoidCallback onTap;
  final IconData icon;
  final bool busy;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, color: Colors.white, size: 22),
    ),
  );
}
