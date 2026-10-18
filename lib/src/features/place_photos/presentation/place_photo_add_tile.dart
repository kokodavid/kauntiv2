import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';

/// The dashed "Add photo" card: first in the strip and in the gallery.
/// Offline it turns grey and says why it can't be used.
class PlacePhotoAddTile extends StatelessWidget {
  const PlacePhotoAddTile({
    super.key,
    required this.onPressed,
    this.offline = false,
    this.width = 112,
    this.height = 132,
    this.label = 'Add photo',
  });

  final VoidCallback onPressed;
  final bool offline;
  final double width;
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = offline ? AppColors.disabledText : AppColors.accent;
    return Semantics(
      button: true,
      enabled: !offline,
      label: offline ? 'Connect to add a photo' : label,
      child: GestureDetector(
        onTap: offline ? null : onPressed,
        child: CustomPaint(
          painter: _DashedBorder(
            offline ? AppColors.lockedStroke : AppColors.accent,
          ),
          child: Container(
            width: width,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: offline
                        ? AppColors.photoDisabledFill
                        : AppColors.accentTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    offline ? Icons.wifi_off : Icons.add_a_photo_outlined,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offline ? 'Connect to add a photo' : label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: offline
                        ? AppColors.disabledText
                        : AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The wide version used when the place has no photos yet.
class PlacePhotoEmptyInvite extends StatelessWidget {
  const PlacePhotoEmptyInvite({
    super.key,
    required this.onPressed,
    this.offline = false,
  });

  final VoidCallback onPressed;
  final bool offline;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: offline ? null : onPressed,
    child: CustomPaint(
      painter: _DashedBorder(
        offline ? AppColors.lockedStroke : AppColors.accent,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: offline
                    ? AppColors.photoDisabledFill
                    : AppColors.accentTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                offline ? Icons.wifi_off : Icons.add_a_photo_outlined,
                color: offline ? AppColors.disabledText : AppColors.accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offline
                        ? 'Connect to add a photo'
                        : 'Be the first to add a photo',
                    style: const TextStyle(
                      fontFamily: AppTypeScale.family,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Been here? Your photo helps the next visitor.',
                    style: TextStyle(
                      fontFamily: AppTypeScale.family,
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          const Radius.circular(16),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
