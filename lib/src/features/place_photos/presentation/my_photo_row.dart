import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../design/app_colors.dart';
import '../application/place_photos_providers.dart';
import '../domain/photo_submission.dart';

/// One submission on My photos: thumbnail (none for a Not published photo),
/// place, when it was sent, where it stands, the team's reason, and the
/// actions that make sense for that status.
class MyPhotoRow extends ConsumerWidget {
  const MyPhotoRow({
    super.key,
    required this.submission,
    required this.handle,
    required this.unseen,
    required this.onOpenPlace,
    required this.onRemove,
    required this.onDismiss,
    required this.last,
  });

  final PhotoSubmission submission;
  final String? handle;

  /// Show the blue dot (reviewed since the user last looked).
  final bool unseen;
  final VoidCallback onOpenPlace;
  final VoidCallback onRemove;
  final VoidCallback onDismiss;
  final bool last;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _meta {
    final d = submission.createdAt.toLocal();
    final sent = 'Sent ${d.day} ${_months[d.month - 1]}';
    final county = submission.countyName;
    return county == null ? sent : '$county · $sent';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = submission;
    final (String status, Color color, String? reason) = switch (s.status) {
      PhotoSubmissionStatus.pending => (
        'Awaiting review',
        AppColors.mutedForeground,
        null,
      ),
      PhotoSubmissionStatus.rejected => (
        'Not published',
        AppColors.dangerSoftForeground,
        s.rejectReason ?? 'It did not meet our photo guidelines.',
      ),
      PhotoSubmissionStatus.approved when !s.shown => (
        'No longer shown',
        AppColors.mutedForeground,
        'Taken down after a later check. Questions? hello@kaunti47.com',
      ),
      PhotoSubmissionStatus.approved => (
        handle == null ? 'Live' : 'Live · Photo by @$handle',
        AppColors.newCountyText,
        null,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.softDivider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          _Thumb(submission: s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onOpenPlace,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                s.placeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTypeScale.family,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.mutedForeground,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (unseen)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                Text(_meta, style: _small),
                if (s.caption != null && s.caption!.isNotEmpty)
                  Text(
                    '"${s.caption}"',
                    style: const TextStyle(
                      fontFamily: AppTypeScale.family,
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.headingText,
                    ),
                  ),
                Text(
                  status,
                  style: TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (reason != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      reason,
                      style: const TextStyle(
                        fontFamily: AppTypeScale.family,
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.headingText,
                      ),
                    ),
                  ),
                if (s.isPending || s.isRejected)
                  Row(
                    children: [
                      if (s.isPending)
                        _Action(
                          'Remove',
                          AppColors.dangerSoftForeground,
                          onRemove,
                        ),
                      if (s.isRejected) ...[
                        _Action('Send another', AppColors.accent, onOpenPlace),
                        _Action('Dismiss', AppColors.headingText, onDismiss),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _small = TextStyle(
    fontFamily: AppTypeScale.family,
    fontSize: 12,
    color: AppColors.mutedForeground,
  );
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.color, this.onPressed);

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      foregroundColor: color,
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class _Thumb extends ConsumerWidget {
  const _Thumb({required this.submission});

  final PhotoSubmission submission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = submission.thumbPath;
    final url =
        submission.publishedThumbnailUrl ??
        (path == null
            ? null
            : ref.watch(pendingThumbnailUrlProvider(path)).value);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: ColoredBox(
          color: AppColors.photoTileFill,
          child: url == null || submission.isRejected
              ? const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.disabledText,
                )
              : Opacity(
                  opacity: submission.shown ? 1 : 0.45,
                  child: Image(
                    image: appNetworkImage(
                      url,
                      cacheKey: submission.id,
                      cacheWidth: 168,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
        ),
      ),
    );
  }
}
