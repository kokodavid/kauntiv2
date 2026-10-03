part of 'trip_share_sheet.dart';

/// The Trip's own synced photos, oldest first, each tappable to pick it
/// for the preview/share/save - plus a trailing "From phone" tile that
/// opens the system photo picker. Scrolls horizontally rather than
/// wrapping, same as the Claude-Design "Share Sheet 3a" reference.
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.media,
    required this.selectedId,
    required this.onSelect,
    required this.onPickFromPhone,
  });

  final List<JourneyMediaItem> media;
  final String? selectedId;
  final ValueChanged<JourneyMediaItem> onSelect;
  final VoidCallback onPickFromPhone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // +6 over the thumb column's own ~78px (60 image + 4 gap + the
      // time label) - headroom for the selected thumb's glow ring and
      // checkmark badge below, which paint above the 60x60 image via a
      // spreading BoxShadow and a Positioned(top: -5) badge. Without it,
      // ListView's default Clip.hardEdge (flush with this box's top
      // edge) clips the top of that ring/badge off a selected thumb.
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 6),
        children: [
          for (final item in media) ...[
            _PhotoThumb(
              item: item,
              selected: item.id == selectedId,
              onTap: () => onSelect(item),
            ),
            const SizedBox(width: 8),
          ],
          if (media.isNotEmpty)
            Container(
              width: 1,
              height: 44,
              margin: const EdgeInsets.only(top: 8, right: 8),
              color: AppColors.cardBorder,
            ),
          _FromPhoneTile(onTap: onPickFromPhone),
        ],
      ),
    );
  }
}
