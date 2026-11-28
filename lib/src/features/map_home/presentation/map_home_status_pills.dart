import 'package:flutter/material.dart';

import 'map_home_location_pill.dart';
import 'map_home_pending_claim_pill.dart';

/// The pills that ride above Home's collapsed sheet: a pending claim's
/// countdown over the location status.
class MapHomeStatusPills extends StatelessWidget {
  const MapHomeStatusPills({
    super.key,
    this.onOpenLocationTiers,
    this.claimedCountyCodes = const {},
  });

  final VoidCallback? onOpenLocationTiers;
  final Set<int> claimedCountyCodes;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapHomePendingClaimPill(claimedCountyCodes: claimedCountyCodes),
        MapHomeLocationPill(onOpen: onOpenLocationTiers),
      ],
    );
  }
}
