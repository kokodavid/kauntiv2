import 'package:flutter/material.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../../design/app_colors.dart';

/// A place's small photo, or a quiet block when it has none.
class PlanPlaceThumb extends StatelessWidget {
  const PlanPlaceThumb({
    super.key,
    required this.url,
    this.size = 48,
    this.custom = false,
  });

  final String? url;
  final double size;

  /// A place from outside the Kaunti47 list: a pin instead of a landscape.
  final bool custom;

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
              onError: (_, _) {},
            ),
    ),
    child: url == null
        ? Icon(
            custom ? Icons.place_outlined : Icons.landscape_outlined,
            size: 20,
            color: AppColors.mutedForeground,
          )
        : null,
  );
}
