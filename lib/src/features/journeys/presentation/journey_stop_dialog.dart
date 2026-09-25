import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

enum JourneyStopChoice { save, discard }

/// Asks how to end a Journey: save it, discard it, or keep going (null).
Future<JourneyStopChoice?> showJourneyStopDialog(BuildContext context) {
  return showDialog<JourneyStopChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Stop this Journey?'),
      content: const Text(
        'Save it to your Journeys and upload it to your account, or '
        "discard it: the route is deleted from this phone and can't be "
        'recovered.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(JourneyStopChoice.discard),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Discard'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep going'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(JourneyStopChoice.save),
          child: const Text('Stop and save'),
        ),
      ],
    ),
  );
}
