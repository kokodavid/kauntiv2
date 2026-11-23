import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_photo_viewer.dart';
import '../../../design/app_colors.dart';

/// Place Detail's 220 pt header: swipeable photos with the name and
/// county over a gradient, and a photo counter (the back and save
/// buttons are the page's, floated over this -- see
/// `_HeaderIconButton`/`_HeaderSaveButton` in `place_detail_screen.dart`).
/// The category pill that used to float top right has moved into the
/// About section, now that save needs that corner. Without photos it
/// keeps its height (a plain panel saying so), so the page below never
/// jumps.
class PlaceDetailHeader extends StatefulWidget {
  const PlaceDetailHeader({
    super.key,
    required this.images,
    required this.title,
    required this.countyName,
    this.credits = const [],
  });

  static const height = 220.0;

  final List<String> images;
  final String title;
  final String countyName;

  /// "@username" per photo, null where nobody needs crediting.
  final List<String?> credits;

  @override
  State<PlaceDetailHeader> createState() => _PlaceDetailHeaderState();
}

class _PlaceDetailHeaderState extends State<PlaceDetailHeader> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(BuildContext context, int index) => openAppPhotoViewer(context, [
    for (var i = 0; i < widget.images.length; i++)
      AppViewerPhoto(
        id: widget.images[i],
        url: widget.images[i],
        caption: i < widget.credits.length && widget.credits[i] != null
            ? 'Photo by ${widget.credits[i]}'
            : null,
      ),
  ], initialIndex: index);

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final credit = _page < widget.credits.length ? widget.credits[_page] : null;
    return Container(
      height: PlaceDetailHeader.height,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            const _NoPhoto()
          else
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _open(context, index),
                child: Image(
                  image: appNetworkImage(images[index]),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const _NoPhoto(),
                ),
              ),
            ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xBF000000)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: IgnorePointer(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTypeScale.family,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.countyName,
                          style: const TextStyle(
                            fontFamily: AppTypeScale.family,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        if (credit != null)
                          Text(
                            'Photo by $credit',
                            style: const TextStyle(
                              fontFamily: AppTypeScale.family,
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (images.length > 1)
                    Text(
                      '${_page + 1} / ${images.length}',
                      style: const TextStyle(
                        fontFamily: AppTypeScale.family,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPhoto extends StatelessWidget {
  const _NoPhoto();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.photoPlaceholder,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 30, color: Colors.white70),
            SizedBox(height: 4),
            Text(
              'No photo yet',
              style: TextStyle(
                fontFamily: AppTypeScale.family,
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
