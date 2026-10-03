import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';

enum JourneyStopChoice { save, discard }

/// Asks how to end a Journey: save it, discard it, or keep going (null).
///
/// Styled like [showAppConfirmSheet] (icon circle, title, one line of
/// body copy, stacked buttons) rather than a bespoke [AlertDialog] - that
/// sheet's own doc comment already calls out "stopping one" as a planned
/// use for the same bottom-sheet "03 · DIALOG" design. It isn't built on
/// [showAppConfirmSheet] itself, though: this needs three outcomes
/// (save / discard / keep going) where that one only ever returns a
/// bool, so this is its own three-button sheet sharing the same visual
/// language instead.
Future<JourneyStopChoice?> showJourneyStopDialog(BuildContext context) {
  return showModalBottomSheet<JourneyStopChoice>(
    context: context,
    // useRootNavigator: true - same fix as this app's other sheets - so
    // this sits above AppShell's floating bottom nav bar (and, here,
    // over the full-screen recording map's own controls).
    useRootNavigator: true,
    backgroundColor: Colors.white,
    barrierColor: AppColors.sheetBarrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _JourneyStopSheet(),
  );
}

class _JourneyStopSheet extends StatelessWidget {
  const _JourneyStopSheet();

  @override
  Widget build(BuildContext context) {
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
                // Accent, not danger: stopping and saving is the main,
                // non-destructive path here - only the "Discard" button
                // itself carries the danger colour.
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stop_circle_outlined,
                size: 24,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Stop this Trip?',
              style: AppTextStyles.confirmSheetTitle,
            ),
            const SizedBox(height: 6),
            const Text(
              'Save it to your Trips and upload it to your account, or '
              "discard it: the route is deleted from this phone and can't "
              'be recovered.',
              style: AppTextStyles.confirmSheetBody,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(JourneyStopChoice.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Stop and save',
                  style: AppTextStyles.confirmSheetButtonLabel,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pop(JourneyStopChoice.discard),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.danger),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Discard',
                  style: AppTextStyles.confirmSheetButtonLabel.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.buttonForeground,
                ),
                child: Text(
                  'Keep going',
                  style: AppTextStyles.confirmSheetButtonLabel.copyWith(
                    color: AppColors.buttonForeground,
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
