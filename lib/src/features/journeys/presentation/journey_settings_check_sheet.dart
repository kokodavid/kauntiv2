import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/journey_device_settings.dart';

/// What to do after the pre-trip check: start anyway, or open the phone's
/// settings first. Dismissing the sheet (null) means do not start.
enum JourneySettingsChoice { startAnyway, openSettings }

/// Tells the person about power settings that can cut a Trip short, before
/// it starts. It warns and never blocks: they can always start anyway.
Future<JourneySettingsChoice?> showJourneySettingsCheck(
  BuildContext context, {
  required List<JourneySettingsWarning> warnings,
  required bool canOpenSettings,
}) {
  return showModalBottomSheet<JourneySettingsChoice>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: AppColors.sheetBarrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _SettingsCheckSheet(
      warnings: warnings,
      canOpenSettings: canOpenSettings,
    ),
  );
}

/// One plain sentence per warning.
String journeySettingsWarningText(JourneySettingsWarning warning) =>
    switch (warning) {
      JourneySettingsWarning.batterySaver =>
        'Battery saver is on. It can pause location in the background, so '
            'the route may have gaps. Turn it off for the best recording.',
      JourneySettingsWarning.lowBattery =>
        'Your battery is low. The phone may turn battery saver on by itself '
            'and cut the recording short.',
      JourneySettingsWarning.batteryOptimisation =>
        'This phone may stop Kaunti47 in the background to save battery. In '
            'Settings, set battery use for Kaunti47 to unrestricted.',
    };

class _SettingsCheckSheet extends StatelessWidget {
  const _SettingsCheckSheet({
    required this.warnings,
    required this.canOpenSettings,
  });

  final List<JourneySettingsWarning> warnings;
  final bool canOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.battery_alert_outlined,
                  size: 24,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Before you start',
                style: AppTextStyles.confirmSheetTitle,
              ),
              const SizedBox(height: 6),
              for (final warning in warnings) ...[
                Text(
                  journeySettingsWarningText(warning),
                  style: AppTextStyles.confirmSheetBody,
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(JourneySettingsChoice.startAnyway),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Start anyway',
                    style: AppTextStyles.confirmSheetButtonLabel,
                  ),
                ),
              ),
              if (canOpenSettings) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(JourneySettingsChoice.openSettings),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.accent),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Open settings',
                      style: AppTextStyles.confirmSheetButtonLabel.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
