import 'package:flutter/material.dart';

import '../../../core/widgets/offline_hint.dart';
import '../../../design/app_colors.dart';
import '../domain/map_home_models.dart';

/// Home's expanded sheet while offline: what still works and what needs a
/// connection. The banner carries the "You're offline" line, the saved time
/// and Retry.
class MapHomeOfflineBody extends StatelessWidget {
  const MapHomeOfflineBody({super.key, required this.board});

  final MapHomeBoardData board;

  @override
  Widget build(BuildContext context) {
    final pending = board.countyBadges
        .where((b) => b.state == MapHomeCountyBadgeState.pending)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfflineHintBody(
            text: pending == 0
                ? 'Counties you visit are still saved.'
                : '$pending ${pending == 1 ? 'county is' : 'counties are'} '
                      'saved on this phone and will sync when you reconnect.',
          ),
          const SizedBox(height: 10),
          const Text(
            'Places near you and suggestions need a connection.',
            style: TextStyle(fontSize: 12.5, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

/// The collapsed card while offline: the same hint, in the card's slot.
class MapHomeOfflineCollapsed extends StatelessWidget {
  const MapHomeOfflineCollapsed({super.key, required this.board});

  final MapHomeBoardData board;

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
    child: Center(
      child: OfflineHintBody(text: 'Counties you visit are still saved.'),
    ),
  );
}
