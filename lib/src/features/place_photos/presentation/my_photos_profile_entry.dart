import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/place_photos_providers.dart';

/// What Profile's "My photos" row needs: the line under the title and
/// whether to show the blue dot.
typedef MyPhotosEntryBuilder =
    Widget Function(BuildContext context, String subtitle, bool unseen);

/// Profile's "My photos" entry. Builds nothing while the feature is off;
/// the row itself is drawn by [builder] (app/ passes Profile's own tile).
class MyPhotosProfileEntry extends ConsumerWidget {
  const MyPhotosProfileEntry({super.key, required this.builder});

  final MyPhotosEntryBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(placePhotosEnabledProvider).value != true) {
      return const SizedBox.shrink();
    }
    final unseen = ref.watch(unseenPhotoCountProvider).value ?? 0;
    final subtitle = unseen == 0
        ? 'Photos you have sent to places'
        : unseen == 1
        ? '1 photo reviewed'
        : '$unseen photos reviewed';
    return builder(context, subtitle, unseen > 0);
  }
}
