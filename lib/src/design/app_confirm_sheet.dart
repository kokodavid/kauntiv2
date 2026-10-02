import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// A bottom-sheet confirm dialog, matching the Claude-Design "03 · DIALOG"
/// reference ("Bottom sheet: icon, title, one line, stacked buttons"): a
/// tinted icon circle, a title, one short line of body copy, and a filled
/// primary button over an optional outlined secondary ("Cancel") button.
/// Reusable - any screen asking the user to confirm something (deleting a
/// Trip today; stopping one, or a county-unlock celebration, later) opens
/// the same sheet rather than a bespoke [AlertDialog].
///
/// Returns true if the primary button was tapped, false otherwise (the
/// secondary button, a back gesture, or tapping outside the sheet).
Future<bool> showAppConfirmSheet(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required Color iconTint,
  required String title,
  required String body,
  required String primaryLabel,
  Color primaryColor = AppColors.accent,
  String? secondaryLabel = 'Cancel',
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    // useRootNavigator: true - same fix as this app's other sheets - so
    // this sits above AppShell's floating bottom nav bar.
    useRootNavigator: true,
    backgroundColor: Colors.white,
    barrierColor: AppColors.sheetBarrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _AppConfirmSheet(
      icon: icon,
      iconColor: iconColor,
      iconTint: iconTint,
      title: title,
      body: body,
      primaryLabel: primaryLabel,
      primaryColor: primaryColor,
      secondaryLabel: secondaryLabel,
    ),
  );
  return confirmed ?? false;
}

class _AppConfirmSheet extends StatelessWidget {
  const _AppConfirmSheet({
    required this.icon,
    required this.iconColor,
    required this.iconTint,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.primaryColor,
    required this.secondaryLabel,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconTint;
  final String title;
  final String body;
  final String primaryLabel;
  final Color primaryColor;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryLabel;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.trackInactive,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(title, style: AppTextStyles.confirmSheetTitle),
            const SizedBox(height: 6),
            Text(body, style: AppTextStyles.confirmSheetBody),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  primaryLabel,
                  style: AppTextStyles.confirmSheetButtonLabel,
                ),
              ),
            ),
            if (secondary != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.buttonForeground,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    secondary,
                    style: AppTextStyles.confirmSheetButtonLabel.copyWith(
                      color: AppColors.buttonForeground,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
