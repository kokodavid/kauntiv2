import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_confirm_sheet.dart';
import '../../../design/app_text_input_sheet.dart';
import '../application/journey_history.dart';
import '../domain/journey_summary.dart';

/// Opens the "Rename Trip" sheet for [journey] and saves the result,
/// showing a Snackbar if it fails. Shared by every place a Trip's "..."
/// menu shows up, so Rename behaves identically everywhere.
Future<void> renameJourneyTrip(
  BuildContext context,
  WidgetRef ref,
  JourneySummary journey,
) async {
  final title = await showAppTextInputSheet(
    context,
    title: 'Rename Trip',
    initialValue: journey.title,
    saveLabel: 'Save name',
    hintText: 'Trip name',
  );
  if (title == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(journeyHistoryListProvider.notifier).rename(journey, title);
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text("Couldn't rename it. Try again.")),
    );
  }
}

/// Confirms with the "Delete this Trip?" sheet, then deletes [journey],
/// showing a Snackbar if it fails. Shared the same way as
/// [renameJourneyTrip].
Future<void> deleteJourneyTrip(
  BuildContext context,
  WidgetRef ref,
  JourneySummary journey,
) async {
  final confirmed = await showAppConfirmSheet(
    context,
    icon: Icons.delete_outline,
    iconColor: AppColors.danger,
    iconTint: AppColors.dangerTint,
    title: 'Delete this Trip?',
    body: journey.isUploaded
        ? "'${journey.title}' is removed from your account and this phone."
        : "'${journey.title}' hasn't uploaded yet, so it'll be removed from "
              'this phone for good.',
    primaryLabel: 'Delete Trip',
    primaryColor: AppColors.danger,
  );
  if (!confirmed || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(journeyHistoryListProvider.notifier).delete(journey);
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text("Couldn't delete it. Try again.")),
    );
  }
}
