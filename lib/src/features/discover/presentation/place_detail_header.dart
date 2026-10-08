import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../design/app_colors.dart';
import '../domain/place_category.dart';
import 'place_category_style.dart';

/// Place Detail's 240 pt header: swipeable photos with the category, the
/// name and county over a gradient, and a photo counter (the back button
/// is the page's, floated over this). Without photos it keeps its height (a plain panel saying so),
/// so the page below never jumps.
class PlaceDetailHeader extends StatefulWidget {
  const PlaceDetailHeader({
    super.key,
    required this.images,
    required this.title,
    required this.countyName,
    required this.category,
  });

  static const height = 240.0;

  final List<String> images;
  final String title;
  final String countyName;
  final PlaceCategory category;

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

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
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
              itemBuilder: (context, index) => Image(
                image: appNetworkImage(images[index]),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _NoPhoto(),
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
            right: 12,
            top: 12,
            child: _CategoryPill(category: widget.category),
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
                            fontSize: 22,
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

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});

  final PlaceCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.backButtonBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: category.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(category.label, style: AppTypeScale.small),
        ],
      ),
    );
  }
}
