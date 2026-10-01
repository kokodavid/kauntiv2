String? journeyPlaceThumbnail(Object? images) {
  if (images is! List) return null;
  final sorted = [...images.whereType<Map<String, dynamic>>()]
    ..sort(
      (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
        (b['sort_order'] as num?) ?? 0,
      ),
    );
  return sorted.isEmpty ? null : sorted.first['thumbnail_url'] as String?;
}
