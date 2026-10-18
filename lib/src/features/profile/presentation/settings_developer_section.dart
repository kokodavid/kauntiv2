import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'settings_widgets.dart';

/// Dev-build-only: the existing `LOCATION_DIAGNOSTICS`-gated tool,
/// relocated here from Profile's tile list. [onOpenLocationDiagnostics]
/// is only non-null when the caller has already checked
/// `LocationDiagnostics.enabledFor(...)` (same gate the router uses),
/// so this section renders nothing in a release build.
class SettingsDeveloperSection extends StatelessWidget {
  const SettingsDeveloperSection({
    super.key,
    required this.onOpenLocationDiagnostics,
    this.onOpenPushStatus,
    this.onOpenCountyOrder,
  });

  final VoidCallback? onOpenLocationDiagnostics;

  /// Dev builds only; null hides the row.
  final VoidCallback? onOpenPushStatus;

  /// Dev builds only; null hides the row.
  final VoidCallback? onOpenCountyOrder;

  @override
  Widget build(BuildContext context) {
    final onTap = onOpenLocationDiagnostics;
    final onPush = onOpenPushStatus;
    final onOrder = onOpenCountyOrder;
    if (onTap == null && onPush == null && onOrder == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel(
          'Developer',
          trailing: Text(
            'Dev build only',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB45309),
            ),
          ),
        ),
        SettingsCard(
          children: [
            if (onTap != null)
              SettingsActionRow(
                title: 'Location diagnostics',
                subtitle: 'Record and share a device report',
                divider: onPush != null || onOrder != null,
                onTap: onTap,
              ),
            if (onPush != null)
              SettingsActionRow(
                title: 'Push status',
                subtitle: 'Why this phone is or is not registered',
                divider: onOrder != null,
                onTap: onPush,
              ),
            if (onOrder != null)
              SettingsActionRow(
                title: 'County order',
                subtitle: 'Save the county order for your existing trips',
                onTap: onOrder,
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.listDivider),
      ],
    );
  }
}
