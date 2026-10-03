part of 'trip_share_sheet.dart';

class _ShapeChip extends StatelessWidget {
  const _ShapeChip({
    required this.shape,
    required this.selected,
    required this.onTap,
  });

  final _ShareShape shape;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              shape.label,
              style: _Styles.shapeLabel.copyWith(
                color: selected
                    ? AppColors.buttonForeground
                    : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(width: 6),
            Text(shape.ratioLabel, style: _Styles.shapeRatio),
          ],
        ),
      ),
    );
  }
}
