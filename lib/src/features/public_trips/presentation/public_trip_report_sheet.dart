import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/public_trip_viewer_providers.dart';
import '../domain/public_trip_failure.dart';
import '../domain/public_trip_report_reason.dart';
import 'public_trip_widgets.dart';

/// Asks why a public trip is being reported and sends the report. The author
/// is never told who reported.
Future<void> showPublicTripReportSheet(
  BuildContext context, {
  required String publicationId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: AppColors.sheetBarrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _ReportSheet(publicationId: publicationId),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.publicationId});

  final String publicationId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  PublicTripReportReason? _reason;
  final _details = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(publicTripViewerActionsProvider.notifier)
          .report(widget.publicationId, reason, details: _details.text);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      showAppToast(
        context,
        variant: AppToastVariant.success,
        title: 'Report sent',
        message: 'Thanks. A moderator will take a look.',
      );
      navigator.pop();
    } on PublicTripFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report this trip', style: AppTextStyles.confirmSheetTitle),
            const SizedBox(height: 4),
            const Text(
              'Your report is private. The author will not see who sent it.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 8),
            RadioGroup<PublicTripReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: [
                  for (final reason in PublicTripReportReason.values)
                    RadioListTile<PublicTripReportReason>(
                      value: reason,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        reason.label,
                        style: AppTextStyles.listItemTitle,
                      ),
                      subtitle: Text(
                        reason.hint,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _details,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Anything else we should know? (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) PublicTripNote(_error!, isError: true),
            const SizedBox(height: 12),
            PublicTripPrimaryButton(
              label: 'Send report',
              busy: _busy,
              onPressed: _reason == null ? null : () => unawaited(_send()),
            ),
          ],
        ),
      ),
    );
  }
}
