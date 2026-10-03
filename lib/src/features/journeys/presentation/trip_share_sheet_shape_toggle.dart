part of 'trip_share_sheet.dart';

class _ShapeToggle extends StatelessWidget {
  const _ShapeToggle({required this.shape, required this.onChanged});

  final _ShareShape shape;
  final ValueChanged<_ShareShape> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.lockedFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final option in _ShareShape.values)
            Expanded(
              child: _ShapeChip(
                shape: option,
                selected: option == shape,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}
