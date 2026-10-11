
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/offline_screen.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/feedback_providers.dart';
import '../application/feedback_submit_providers.dart';
import 'feedback_report_tile.dart';

/// The tester's own reports and where each one stands. This is where the
/// team's replies show up.
class FeedbackReportsScreen extends ConsumerWidget {
  const FeedbackReportsScreen({super.key, required this.onSendFeedback});

  final VoidCallback onSendFeedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(myFeedbackProvider);
    final waiting = ref.watch(feedbackOutboxSyncProvider).value ?? 0;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text(
          'My reports',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        titleSpacing: 12,
        backgroundColor: AppColors.pageBackground,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 68,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: AppBackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: reports.when(
          loading: () => const Center(
            child: AppProgressIndicator(color: AppColors.accent, radius: 14),
          ),
          error: (error, stack) => OfflineScreen(
            message:
                'Your reports load from the internet. Check your data or '
                'Wi‑Fi, then try again.',
            onRetry: () => ref.invalidate(myFeedbackProvider),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: () => ref.refresh(myFeedbackProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (waiting > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      waiting == 1
                          ? '1 report is saved on this phone and will be '
                                'sent when you have a connection.'
                          : '$waiting reports are saved on this phone and '
                                'will be sent when you have a connection.',
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                    ),
                  ),
                if (items.isEmpty)
                  _Empty(onSendFeedback: onSendFeedback)
                else
                  for (final report in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FeedbackReportTile(report: report),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onSendFeedback});

  final VoidCallback onSendFeedback;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 44,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(height: 14),
          Text(
            'No reports yet',
            style: AppTextStyles.heading.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Found a bug or have an idea? Tell us.',
            style: AppTextStyles.bodyMuted.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onSendFeedback,
            child: Text(
              'Send feedback',
              style: AppTextStyles.buttonLabelSecondary.copyWith(
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
