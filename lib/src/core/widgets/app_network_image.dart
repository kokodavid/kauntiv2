// Prefixed so tools/check_architecture.py's hand-written-provider rule,
// which is about Riverpod, doesn't match Flutter's ImageProvider types.
import 'package:cached_network_image/cached_network_image.dart' as cached;
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cache;

/// Room for every map pin, place photo and Trip photo the app shows, kept
/// for 60 days. The package default (200 files, 30 days) is small enough
/// that browsing the map would keep evicting and re-downloading images.
final cache.CacheManager _imageCache = cache.CacheManager(
  cache.Config(
    'kaunti47_images',
    stalePeriod: const Duration(days: 60),
    maxNrOfCacheObjects: 1000,
  ),
);

/// Every remote image in the app goes through here so it's cached on disk,
/// not just in memory. Plain `Image.network`/`NetworkImage` downloaded every
/// photo again on each launch, which pushed the Supabase dev project past
/// its egress quota.
///
/// [cacheKey]: for URLs that change between fetches of the same file (Trip
/// photos' hourly signed URLs) - pass a stable ID so the device reuses its
/// copy instead of downloading it again under a new URL.
///
/// [cacheWidth]: decode at this pixel width to save memory for small
/// thumbnails. It doesn't change what's downloaded.
widgets.ImageProvider<Object> appNetworkImage(
  String url, {
  String? cacheKey,
  int? cacheWidth,
}) {
  final widgets.ImageProvider<Object> image = cached.CachedNetworkImageProvider(
    url,
    cacheKey: cacheKey,
    cacheManager: _imageCache,
  );
  return widgets.ResizeImage.resizeIfNeeded(cacheWidth, null, image);
}
