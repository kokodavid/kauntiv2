import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/feedback_models.dart';

/// Shown after a report is filed (with its reference) or saved for later.
class FeedbackConfirmation extends StatelessWidget {
  const FeedbackConfirmation({
    super.key,
    required this.submission,
    required this.onDone,
    required this.onOpenReports,
  });

  final FeedbackSubmission submission;
  final VoidCallback onDone;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    final receipt = submission.receipt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        children: [
          const Spacer(),
          Icon(
            receipt == null ? Icons.schedule_send_outlined : Icons.check_circle,
            size: 56,
            color: receipt == null ? AppColors.accent : AppColors.legendHome,
          ),
          const SizedBox(height: 16),
          Text(
            receipt == null ? 'Saved on your phone' : 'Thank you',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            receipt == null
                ? "You're offline, so this report will be sent as soon as "
                      'you have a connection.'
                : 'Your report has been received. Keep this number if you '
                      'want to ask about it.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted.copyWith(fontSize: 14, height: 1.4),
          ),
          if (receipt != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                receipt.reference,
                style: AppTextStyles.heading.copyWith(
                  fontSize: 22,
                  color: AppColors.accent,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          if (submission.filesNotSent > 0) ...[
            const SizedBox(height: 14),
            Text(
              submission.filesNotSent == 1
                  ? "1 file couldn't be uploaded. The report itself was sent."
                  : "${submission.filesNotSent} files couldn't be uploaded. "
                        'The report itself was sent.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.dangerSoftForeground,
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentForeground,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Done', style: AppTextStyles.buttonLabel),
            ),
          ),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: TextButton(
              onPressed: onOpenReports,
              child: Text(
                'See my reports',
                style: AppTextStyles.buttonLabelSecondary.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
