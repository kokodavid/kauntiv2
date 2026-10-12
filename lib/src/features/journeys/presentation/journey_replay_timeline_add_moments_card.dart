part of 'journey_replay_timeline.dart';

/// The "fill the gap" card: a headline/message pair plus an "Add photos"
/// / "Add note" pill pair (Claude-Design "2a" reference), with an
/// optional link to opt into the camera-roll auto-match - shown only
/// while that access hasn't been granted yet, so it's an invitation, not
/// a standing nag once the answer is already known. [title]/[message] let
/// this double as both the fully-empty-timeline card
/// and the lighter inline "no photos yet" suggestion (see
/// the Trip media sheet) without duplicating the layout.
class _AddMomentsCard extends StatelessWidget {
  const _AddMomentsCard({
    required this.title,
    required this.message,
    required this.onAddPhotos,
    required this.addingPhotos,
    required this.showFindPhotosLink,
    required this.onFindPhotos,
  });

  final String title;
  final String message;
  final VoidCallback onAddPhotos;
  final bool addingPhotos;
  final bool showFindPhotosLink;
  final VoidCallback onFindPhotos;

  @override
  Widget build(BuildContext context) {
    final pillLabelStyle = AppTypeScale.action.copyWith(
      fontWeight: FontWeight.w600,
    );
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
          Text(title, style: pillLabelStyle),
          const SizedBox(height: 2),
          Text(message, style: AppTypeScale.body),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: addingPhotos ? null : onAddPhotos,
                  icon: addingPhotos
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: AppProgressIndicator(
                            color: Colors.white,
                            radius: 7,
                          ),
                        )
                      : const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 16,
                        ),
                  label: Text(addingPhotos ? 'Adding…' : 'Add photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.accent,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: pillLabelStyle.copyWith(color: Colors.white),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () => showAppToast(
                    context,
                    variant: AppToastVariant.neutral,
                    title: 'Notes are coming soon',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.buttonForeground,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: pillLabelStyle.copyWith(
                      color: AppColors.buttonForeground,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Add note'),
                ),
              ),
            ],
          ),
          if (showFindPhotosLink) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onFindPhotos,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 14, color: AppColors.accent),
                  SizedBox(width: 4),
                  Text(
                    'Find photos from this trip',
                    style: AppTypeScale.action,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
