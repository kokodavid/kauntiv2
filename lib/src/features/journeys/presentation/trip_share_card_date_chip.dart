part of 'trip_share_card.dart';

/// The date pill, top-anchored: a transport-mode icon (when known) plus
/// a short date or date range, on a translucent dark pill so it reads
/// over any photo.
class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.icon,
    required this.textStyle,
  });

  final String label;
  final IconData? icon;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(label, style: textStyle),
        ],
      ),
    ),
  );
}
