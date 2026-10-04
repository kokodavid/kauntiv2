import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../../design/app_colors.dart';
import '../application/public_trip_review_controller.dart';
import '../application/public_trip_review_state.dart';
import 'public_trip_widgets.dart';

/// The trip's photos with a tick to show each one. Nothing is shown unless
/// the owner picks it; the copies the public sees have location and device
/// details removed.
class PublicTripPhotosSection extends ConsumerWidget {
  const PublicTripPhotosSection({
    super.key,
    required this.journeyId,
    required this.state,
  });

  final String journeyId;
  final PublicTripReviewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.photoOptions.isEmpty) return const SizedBox.shrink();
    final controller = ref.read(
      publicTripReviewControllerProvider(journeyId).notifier,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PublicTripSectionTitle(
          'Photos',
          trailing:
              '${state.selectedPhotos.length} of $publicTripMaxPhotos max',
        ),
        const PublicTripNote(
          'Off by default. Photos you pick are copied with their location and device details removed.',
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final option in state.photoOptions)
              _PhotoTile(
                option: option,
                selected: state.selectedPhotos.contains(option.id),
                onTap: () => controller.togglePhoto(option.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PublicTripPhotoOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? 'Photo shown. Tap to hide.' : 'Photo hidden. Tap to show.',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: appNetworkImage(
                  option.url,
                  cacheKey: option.id,
                  cacheWidth: 300,
                ),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: AppColors.secondaryFill),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.accent : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: selected ? AppColors.accent : Colors.white70,
                child: Icon(
                  selected ? Icons.check : Icons.add,
                  size: 15,
                  color: selected ? Colors.white : AppColors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
