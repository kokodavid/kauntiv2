import 'dart:async';

import 'package:flutter/material.dart';

import 'app_network_image.dart';

/// One photo for [openAppPhotoViewer]. [id] is a stable cache key.
class AppViewerPhoto {
  const AppViewerPhoto({required this.id, required this.url, this.caption});

  final String id;
  final String url;

  /// Shown at the bottom of the viewer, e.g. "Photo by @name".
  final String? caption;
}

/// Opens [items] full screen, starting at [initialIndex]; swipe sideways to
/// move between photos. Pinch to zoom; paging pauses while zoomed in.
/// App-wide: Trip photos and Place photos both open here. [onDelete], when
/// given, shows a delete button (the caller owns the confirm and the delete).
void openAppPhotoViewer(
  BuildContext context,
  List<AppViewerPhoto> items, {
  int initialIndex = 0,
  Future<bool> Function(BuildContext context, AppViewerPhoto item)? onDelete,
}) {
  if (items.isEmpty) return;
  unawaited(
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FullScreenPhotos(
              items: items,
              initialIndex: initialIndex.clamp(0, items.length - 1),
              onDelete: onDelete,
            ),
      ),
    ),
  );
}

class _FullScreenPhotos extends StatefulWidget {
  const _FullScreenPhotos({
    required this.items,
    required this.initialIndex,
    this.onDelete,
  });

  final List<AppViewerPhoto> items;
  final int initialIndex;
  final Future<bool> Function(BuildContext context, AppViewerPhoto item)?
  onDelete;

  @override
  State<_FullScreenPhotos> createState() => _FullScreenPhotosState();
}

class _FullScreenPhotosState extends State<_FullScreenPhotos> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late final List<AppViewerPhoto> _items = [...widget.items];
  late int _index = widget.initialIndex;
  var _deleting = false;
  var _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null || _deleting) return;
    final item = _items[_index];
    setState(() => _deleting = true);
    bool removed;
    try {
      removed = await onDelete(context, item);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
    if (!removed || !mounted) return;
    if (_items.length == 1) {
      unawaited(Navigator.of(context).maybePop());
      return;
    }
    setState(() {
      _items.remove(item);
      _index = _index.clamp(0, _items.length - 1);
    });
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
              PageView.builder(
                controller: _pages,
                physics: _zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: _items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _ZoomablePhoto(
                  key: ValueKey(_items[i].id),
                  item: _items[i],
                  onZoomChanged: (zoomed) {
                    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                  },
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
              if (_items.length > 1)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: _CountPill(
                        label: '${_index + 1} / ${_items.length}',
                      ),
                    ),
                  ),
                ),
              if (_items[_index].caption != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: IgnorePointer(
                    child: Text(
                      _items[_index].caption!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

/// One page: the photo inside a pinch-zoom viewer that reports whether it
/// is zoomed so the pager can stop swallowing the pan gesture.
class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({
    super.key,
    required this.item,
    required this.onZoomChanged,
  });

  final AppViewerPhoto item;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        transformationController: _controller,
        onInteractionEnd: (_) =>
            widget.onZoomChanged(_controller.value.getMaxScaleOnAxis() > 1.01),
        child: Image(
          image: appNetworkImage(widget.item.url, cacheKey: widget.item.id),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image_outlined,
            color: Colors.white70,
            size: 48,
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
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
