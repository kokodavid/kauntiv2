part of 'journey_replay_timeline.dart';

/// The camera-roll auto-match card (Claude-Design "2b" reference):
/// "N photos taken on this route", a preview of the first few, and
/// "Add to timeline" (all of them) or "Choose" (a picker to trim the
/// set down).
class _CameraRollMatchCard extends StatelessWidget {
  const _CameraRollMatchCard({
    required this.matches,
    required this.busy,
    required this.onAddAll,
    required this.onChoose,
  });

  final List<CameraRollMatch> matches;
  final bool busy;
  final VoidCallback onAddAll;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final pillLabelStyle = AppTypeScale.action.copyWith(
      fontWeight: FontWeight.w600,
    );
    final preview = matches.take(3).toList();
    final cappedCount = matches.length > CameraRollMatcher.maxAutoAdd
        ? CameraRollMatcher.maxAutoAdd
        : matches.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.emptyTimelineCardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF3FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 17,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      matches.length == 1
                          ? '1 photo taken on this route'
                          : '${matches.length} photos taken on this route',
                      style: pillLabelStyle,
                    ),
                    const Text(
                      'Found in your camera roll',
                      style: AppTypeScale.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final match in preview) ...[
                Expanded(child: _ThumbnailTile(match: match)),
                if (match != preview.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: busy ? null : onAddAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.accent,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: AppProgressIndicator(
                              color: Colors.white,
                              radius: 8,
                            ),
                          )
                        : Text(
                            cappedCount == matches.length
                                ? 'Add to timeline'
                                : 'Add $cappedCount of ${matches.length}',
                            style: pillLabelStyle.copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: busy ? null : onChoose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.buttonForeground,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: pillLabelStyle.copyWith(
                      color: AppColors.buttonForeground,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Choose'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
