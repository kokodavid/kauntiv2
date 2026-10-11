part of 'journey_replay_timeline.dart';

/// The round button at the right of the Trip title (Journey Replay 3a). It
/// opens the Trip media sheet. Shows the photo count; with no photos it
/// shows a dot only when camera-roll matches are waiting.
class _TripMediaButton extends StatelessWidget {
  const _TripMediaButton({
    required this.count,
    required this.hasMatches,
    required this.onPressed,
  });

  final int count;
  final bool hasMatches;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Trip media',
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.emptyTimelineCardBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined, size: 21),
              ),
              if (count > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _TripMediaBadge(label: count > 99 ? '99+' : '$count'),
                )
              else if (hasMatches)
                const Positioned(top: 3, right: 3, child: _TripMediaDot()),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripMediaBadge extends StatelessWidget {
  const _TripMediaBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _TripMediaDot extends StatelessWidget {
  const _TripMediaDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _TripMediaRoundButton extends StatelessWidget {
  const _TripMediaRoundButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : AppColors.foreground;
    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: onPressed == null && icon != null ? 0.5 : 1,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: filled
                  ? AppColors.accent
                  : AppColors.emptyTimelineCardBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: icon == null
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                : Icon(icon, size: 18, color: foreground),
          ),
        ),
      ),
    );
  }
}
