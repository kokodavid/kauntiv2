import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

/// A centered confirm dialog: a title, one line of body copy, then a
/// full-width filled primary button over a borderless "Cancel" text
/// button. The shape Settings' "Sign out" and "Delete account"
/// confirmations both use, instead of a default `AlertDialog`'s
/// side-by-side actions.
///
/// Returns true if the primary button was tapped, false otherwise (the
/// secondary button, a back gesture, or tapping outside the dialog).
Future<bool> showStackedConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String primaryLabel,
  required Color primaryColor,
  String cancelLabel = 'Cancel',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _StackedConfirmDialog(
      title: title,
      body: body,
      primaryLabel: primaryLabel,
      primaryColor: primaryColor,
      cancelLabel: cancelLabel,
    ),
  );
  return confirmed ?? false;
}

class _StackedConfirmDialog extends StatelessWidget {
  const _StackedConfirmDialog({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.primaryColor,
    required this.cancelLabel,
  });

  final String title;
  final String body;
  final String primaryLabel;
  final Color primaryColor;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.confirmSheetTitle),
          const SizedBox(height: 8),
          Text(body, style: AppTextStyles.confirmSheetBody),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                shape: const StadiumBorder(),
              ),
              child: Text(
                primaryLabel,
                style: AppTextStyles.confirmSheetButtonLabel,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.foreground,
              ),
              child: Text(
                cancelLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
