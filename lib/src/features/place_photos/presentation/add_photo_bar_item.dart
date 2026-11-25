import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/connectivity_provider.dart';
import '../../../core/widgets/place_detail_bar_button.dart';
import '../application/place_photos_providers.dart';
import 'place_photo_add_flow.dart';

/// "Add photo" as the fourth item of Place Detail's floating action bar,
/// beside Add to trip, the check-in button and Route. Renders nothing
/// while the place doesn't take photos or the feature is off; offline it
/// stays visible but disabled, matching the old inline tile's behaviour.
class AddPhotoBarItem extends ConsumerWidget {
  const AddPhotoBarItem({
    super.key,
    required this.placeId,
    required this.canAdd,
    this.onChooseUsername,
  });

  final String placeId;

  /// Whether this place takes photos (reviewed and not archived).
  final bool canAdd;
  final VoidCallback? onChooseUsername;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(placePhotosEnabledProvider).value == true;
    if (!(canAdd && enabled)) return const SizedBox.shrink();
    final offline = ref.watch(connectivityProvider).isOffline;
    return PlaceDetailBarButton(
      icon: offline ? Icons.wifi_off : Icons.add_a_photo_outlined,
      label: 'Add photo',
      onPressed: offline
          ? null
          : () => startAddPhoto(
              context,
              ref,
              placeId: placeId,
              onChooseUsername: onChooseUsername,
            ),
    );
  }
}
