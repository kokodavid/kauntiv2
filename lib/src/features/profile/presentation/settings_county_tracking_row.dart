import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../detection/application/county_tracking.dart';
import 'confirm_dialog.dart';
import 'settings_widgets.dart';

/// The "Accurate county times" switch under Location. Off by default; turning
/// it on explains the cost first, and needs location allowed all the time.
class SettingsCountyTrackingRow extends ConsumerWidget {
  const SettingsCountyTrackingRow({super.key});

  Future<void> _change(BuildContext context, WidgetRef ref, bool on) async {
    final tracking = ref.read(countyTrackingProvider.notifier);
    if (!on) {
      await tracking.setEnabled(false);
      return;
    }
    final confirmed = await showStackedConfirmDialog(
      context,
      title: 'Turn on accurate county times?',
      body:
          'Kaunti47 checks your location about every kilometre you travel, '
          'so the time you spend in each county is recorded more '
          'accurately. It uses a little more battery, and Android shows a '
          'notification while it runs.',
      primaryLabel: 'Turn on',
      primaryColor: AppColors.accent,
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!await tracking.setEnabled(true)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Allow location "All the time" first, under Location permission.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(countyTrackingProvider).value ?? false;
    return SettingsToggleRow(
      title: 'Accurate county times',
      subtitle: 'Checks location as you travel. Uses a little more battery.',
      value: on,
      divider: true,
      onChanged: (value) => unawaited(_change(context, ref, value)),
    );
  }
}
