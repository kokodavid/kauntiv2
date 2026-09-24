import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

/// Swipeable hero photos for County and Place Detail (v1's
/// `AppPhotoCarousel` in its `dotsBelowPhoto` mode): rounded photo with
/// [overlay] chrome on top, and a worm-dot page indicator below it when
/// there's more than one photo. No auto-advance, as in v1's detail pages.
class DetailPhotoCarousel extends StatefulWidget {
  const DetailPhotoCarousel({
    super.key,
    required this.images,
    this.overlay,
    this.borderRadius = 20,
  });

  final List<String> images;
  final Widget? overlay;
  final double borderRadius;

  @override
  State<DetailPhotoCarousel> createState() => _DetailPhotoCarouselState();
}

class _DetailPhotoCarouselState extends State<DetailPhotoCarousel> {
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
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            const ColoredBox(color: AppColors.lockedFill)
          else
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) => Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: AppColors.lockedFill),
              ),
            ),
          ?widget.overlay,
        ],
      ),
    );
    if (images.length <= 1) return photo;

    return Column(
      children: [
        Expanded(child: photo),
        const SizedBox(height: 14),
        _CarouselDots(count: images.length, activeIndex: _page),
      ],
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == activeIndex ? 32 : 8,
            height: 6,
            decoration: BoxDecoration(
              color: i == activeIndex
                  ? AppColors.accent
                  : AppColors.trackInactive,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}
