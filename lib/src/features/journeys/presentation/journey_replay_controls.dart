import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/replay_controls.dart';

/// A message in place of the replay (deleted, offline, too few points).
class JourneyReplayMessage extends StatelessWidget {
  const JourneyReplayMessage({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center, style: AppTypeScale.body),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// The round white corner button and "Whole route" pill are shared with
/// other replays; Journeys keeps its own names for them.
typedef JourneyMapButton = ReplayMapButton;
typedef JourneyWholeRoutePill = ReplayWholeRoutePill;
