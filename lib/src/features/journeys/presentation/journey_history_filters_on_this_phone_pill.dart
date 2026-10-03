part of 'journey_history_filters.dart';

/// "On this phone": Trips still waiting to upload. The orange dot flags it
/// as a device-local state rather than a date window.
class _OnThisPhonePill extends StatelessWidget {
  const _OnThisPhonePill({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('journeyOnThisPhoneFilter'),
      color: selected ? AppColors.accent : AppColors.exploreSurface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.exploreBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppColors.pendingFill,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'On this phone',
                maxLines: 1,
                style: AppTypeScale.pill.copyWith(
                  color: selected ? Colors.white : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
