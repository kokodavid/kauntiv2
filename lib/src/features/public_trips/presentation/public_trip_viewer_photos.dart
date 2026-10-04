import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/public_trip_viewer_providers.dart';
import '../domain/public_trip_view.dart';
import 'public_trip_widgets.dart';

/// The photos the owner chose to share, as a horizontal strip. Images load
/// through short-lived links and are not cached on disk, so a withdrawn trip
/// leaves nothing behind on the phone.
class PublicTripViewerPhotos extends ConsumerWidget {
  const PublicTripViewerPhotos({super.key, required this.trip});

  final PublicTripView trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (trip.photos.isEmpty) return const SizedBox.shrink();
    final urls = ref.watch(publicTripPhotoUrlsProvider(trip.id, trip.revision));
    final links = urls.value ?? const <String, String>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PublicTripSectionTitle('Photos', trailing: '${trip.photos.length}'),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: trip.photos.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final url = links[trip.photos[index].id];
              return _Thumb(
                url: url,
                loading: urls.isLoading,
                onTap: url == null ? null : () => _open(context, url),
              );
            },
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, String url) {
    unawaited(
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierColor: Colors.black87,
        builder: (context) => GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white70,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.loading, this.onTap});

  final String? url;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final link = url;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 120,
          height: 120,
          child: link == null
              ? ColoredBox(
                  color: AppColors.trackInactive,
                  child: loading
                      ? null
                      : const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.mutedForeground,
                        ),
                )
              : Image.network(
                  link,
                  fit: BoxFit.cover,
                  cacheWidth: 360,
                  errorBuilder: (context, error, stack) => const ColoredBox(
                    color: AppColors.trackInactive,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
