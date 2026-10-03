part of 'trip_share_sheet.dart';

class _FromPhoneTile extends StatelessWidget {
  const _FromPhoneTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.lockedFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              size: 22,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          const Text('From phone', style: _Styles.thumbTimeSelected),
        ],
      ),
    );
  }
}
