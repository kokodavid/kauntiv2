import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

/// Asks for a new Trip name, prefilled with the current one. Null if
/// cancelled; otherwise the trimmed name, always 1-120 characters.
Future<String?> showJourneyRenameDialog(
  BuildContext context,
  String currentTitle,
) {
  final controller = TextEditingController(text: currentTitle);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename this Trip'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 120,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Trip name'),
        onSubmitted: (value) => _submit(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _submit(context, controller.text),
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _submit(BuildContext context, String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return;
  Navigator.of(context).pop(trimmed);
}
