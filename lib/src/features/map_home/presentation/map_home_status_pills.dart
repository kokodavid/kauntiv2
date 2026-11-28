import 'package:flutter/material.dart';

import 'map_home_location_pill.dart';
import 'map_home_pending_claim_pill.dart';

/// The pills that ride above Home's collapsed sheet: a pending claim's
/// countdown over the location status.
class MapHomeStatusPills extends StatelessWidget {
  const MapHomeStatusPills({super.key, this.onOpenLocationTiers});

  final VoidCallback? onOpenLocationTiers;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MapHomePendingClaimPill(),
        MapHomeLocationPill(onOpen: onOpenLocationTiers),
      ],
    );
  }
}
