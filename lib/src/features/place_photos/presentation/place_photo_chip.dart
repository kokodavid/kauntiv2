import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../domain/photo_submission.dart';

/// The one quiet line under the photos about the user's own submissions
/// for this place. Nothing when there is nothing to say; tapping it opens
/// My photos, where the detail lives.
class PlacePhotoChip extends StatelessWidget {
  const PlacePhotoChip({
    super.key,
    required this.submissions,
    required this.onOpen,
  });

  final List<PhotoSubmission> submissions;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final live = submissions.any(
      (s) => s.unseen && s.status == PhotoSubmissionStatus.approved && s.shown,
    );
    final notPublished = submissions.any((s) => s.unseen && s.isRejected);
    final waiting = submissions.where((s) => s.isPending).length;
    final (String? text, Color? dot, String? action) = live
        ? ('Your photo is live', AppColors.newCountyText, 'View')
        : notPublished
        ? (
            "Your photo wasn't published",
            AppColors.dangerSoftForeground,
            'See why',
          )
        : waiting > 0
        ? (
            waiting == 1
                ? '1 photo awaiting review'
                : '$waiting photos awaiting review',
            AppColors.disabledText,
            null,
          )
        : (null, null, null);
    if (text == null || dot == null) return const SizedBox.shrink();
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: AppTypeScale.family,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontFamily: AppTypeScale.family,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
