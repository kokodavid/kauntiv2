import 'package:flutter/material.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../../design/app_colors.dart';

/// A place's small photo, or a quiet block when it has none.
class PlanPlaceThumb extends StatelessWidget {
  const PlanPlaceThumb({super.key, required this.url, this.size = 48});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.lockedFill,
      borderRadius: BorderRadius.circular(10),
      image: url == null
          ? null
          : DecorationImage(
              image: appNetworkImage(url!, cacheWidth: 144),
              fit: BoxFit.cover,
            ),
    ),
    child: url == null
        ? const Icon(
            Icons.landscape_outlined,
            size: 20,
            color: AppColors.mutedForeground,
          )
        : null,
  );
}
