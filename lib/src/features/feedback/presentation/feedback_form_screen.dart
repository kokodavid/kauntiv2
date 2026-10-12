import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/connectivity_provider.dart';
import '../../../core/services/last_screen.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/offline_hint.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/feedback_submit_providers.dart';
import '../domain/feedback_models.dart';
import 'feedback_attachments_field.dart';
import 'feedback_choice_widgets.dart';
import 'feedback_confirmation.dart';
import 'feedback_text_fields.dart';

/// Beta feedback form (Profile > Beta feedback). Open to testers only; the
/// Profile entry is hidden for everyone else and the database refuses the
/// rest. The report is filed with the screen, app version and phone model
/// the app already knows, so the tester only says what happened.
class FeedbackFormScreen extends ConsumerStatefulWidget {
  const FeedbackFormScreen({super.key, required this.onOpenReports});

  final VoidCallback onOpenReports;

  @override
  ConsumerState<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends ConsumerState<FeedbackFormScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  FeedbackCategory _category = FeedbackCategory.bug;
  FeedbackSeverity? _severity;
  bool _contactOk = false;
  List<FeedbackAttachmentFile> _files = const [];

  /// Kept for the whole screen so a retry never files the report twice.
  final String _clientId = FeedbackDraft.newClientId();

  @override
  void initState() {
    super.initState();
    // A form opened after an earlier report starts blank, not on its receipt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(feedbackSubmitterProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _valid =>
      FeedbackDraft.titleOk(_title.text) &&
      FeedbackDraft.descriptionOk(_description.text) &&
      _severity != null;

  void _send() {
    final severity = _severity;
    if (!_valid || severity == null) return;
    FocusScope.of(context).unfocus();
    unawaited(
      ref
          .read(feedbackSubmitterProvider.notifier)
          .submit(
            FeedbackDraft(
              clientId: _clientId,
              category: _category,
              severity: severity,
              title: _title.text.trim(),
              description: _description.text.trim(),
              contactOk: _contactOk,
              attachments: _files,
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submit = ref.watch(feedbackSubmitterProvider);
    final done = submit.value;
    final sending = submit.isLoading;
    final offline = ref.watch(connectivityProvider.select((s) => s.isOffline));
    final screen = ref.watch(lastScreenProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Beta feedback',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        titleSpacing: 12,
        backgroundColor: Colors.white,
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
        actions: [
          TextButton(
            onPressed: widget.onOpenReports,
            child: const Text('My reports'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: done != null
            ? FeedbackConfirmation(
                submission: done,
                onDone: () => Navigator.of(context).maybePop(),
                onOpenReports: widget.onOpenReports,
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tell us what happened',
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 18,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Thank you for testing. Every report is read.',
                            style: AppTextStyles.bodyMuted.copyWith(
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          if (offline) ...[
                            const SizedBox(height: 10),
                            const OfflineHint(
                              text:
                                  "You're offline. Your report is saved "
                                  "and sent when you're back.",
                            ),
                          ],
                          const FeedbackSectionLabel('What is it about?'),
                          FeedbackCategoryPicker(
                            selected: _category,
                            onChanged: (value) =>
                                setState(() => _category = value),
                          ),
                          const FeedbackSectionLabel('How bad is it?'),
                          FeedbackSeverityPicker(
                            selected: _severity,
                            onChanged: (value) =>
                                setState(() => _severity = value),
                          ),
                          const FeedbackSectionLabel('In a few words'),
                          FeedbackTextField(
                            controller: _title,
                            hint: 'Map flickers when I open Home',
                            maxLength: FeedbackDraft.titleMax,
                            enabled: !sending,
                            onChanged: (_) => setState(() {}),
                          ),
                          const FeedbackSectionLabel('The details'),
                          FeedbackTextField(
                            controller: _description,
                            hint:
                                'What did you do, what did you expect, '
                                'and what happened instead?',
                            maxLength: FeedbackDraft.descriptionMax,
                            minLines: 5,
                            maxLines: 9,
                            enabled: !sending,
                            onChanged: (_) => setState(() {}),
                          ),
                          const FeedbackSectionLabel(
                            'Screenshot or recording (optional)',
                          ),
                          FeedbackAttachmentsField(
                            files: _files,
                            enabled: !sending,
                            onChanged: (value) =>
                                setState(() => _files = value),
                          ),
                          const SizedBox(height: 14),
                          FeedbackContactSwitch(
                            value: _contactOk,
                            enabled: !sending,
                            onChanged: (value) =>
                                setState(() => _contactOk = value),
                          ),
                          const SizedBox(height: 12),
                          FeedbackContextNote(screen: screen),
                          if (submit.hasError) ...[
                            const SizedBox(height: 12),
                            Text(
                              submit.error is FeedbackFailure
                                  ? (submit.error! as FeedbackFailure).message
                                  : "Couldn't send your feedback. Try again.",
                              style: const TextStyle(
                                color: AppColors.dangerSoftForeground,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: sending || !_valid ? null : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.accentForeground,
                          disabledBackgroundColor: _valid
                              ? AppColors.accent
                              : AppColors.secondaryFill,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: sending
                            ? const AppProgressIndicator(
                                color: AppColors.accentForeground,
                                radius: 9,
                              )
                            : Text(
                                'Send feedback',
                                style: AppTextStyles.buttonLabel.copyWith(
                                  color: _valid
                                      ? AppColors.accentForeground
                                      : AppColors.mutedForeground,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
