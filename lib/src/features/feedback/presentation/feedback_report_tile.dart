import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/feedback_models.dart';

/// One of the tester's reports: its reference, title, where it stands, and
/// the team's reply when there is one.
class FeedbackReportTile extends StatelessWidget {
  const FeedbackReportTile({super.key, required this.report});

  final FeedbackReport report;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final response = report.testerResponse;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                report.reference,
                style: AppTextStyles.chipLabel.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
              const Spacer(),
              FeedbackStatusChip(status: report.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.title,
            style: AppTextStyles.listItemTitle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            '${report.category.label} · ${report.severity.label} · '
            '${_date(report.createdAt)}',
            style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
          ),
          if (response != null && response.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'From the team',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    response,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.ink,
                    ),
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

class FeedbackStatusChip extends StatelessWidget {
  const FeedbackStatusChip({super.key, required this.status});

  final FeedbackStatus status;

  static Color _color(FeedbackStatus status) => switch (status) {
    FeedbackStatus.resolved => AppColors.legendHome,
    FeedbackStatus.planned => AppColors.accent,
    FeedbackStatus.investigating => AppColors.pendingFill,
    FeedbackStatus.triaged => AppColors.accent,
    FeedbackStatus.received => AppColors.mutedForeground,
    FeedbackStatus.closed ||
    FeedbackStatus.rejected ||
    FeedbackStatus.duplicate => AppColors.mutedForeground,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
