import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/map_home_models.dart';

/// Lets Home's sheet reach the offline retry without threading it through
/// the board: the screen provides it, the offline sheet reads it.
class MapHomeOfflineScope extends InheritedWidget {
  const MapHomeOfflineScope({
    super.key,
    required this.retrying,
    required this.onRetry,
    required super.child,
  });

  final bool retrying;
  final VoidCallback onRetry;

  static MapHomeOfflineScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MapHomeOfflineScope>();

  @override
  bool updateShouldNotify(MapHomeOfflineScope old) =>
      retrying != old.retrying;
}

/// "Saved 3 weeks ago" / "Saved today, 9:41 AM"; null without a saved copy.
String? mapHomeSavedLabel(DateTime? savedAt, DateTime now) {
  if (savedAt == null) return null;
  final local = savedAt.toLocal();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(local.year, local.month, local.day))
      .inDays;
  if (days <= 0) {
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Saved today, $hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
  }
  if (days == 1) return 'Saved yesterday';
  if (days < 14) return 'Saved $days days ago';
  if (days < 60) return 'Saved ${days ~/ 7} weeks ago';
  return 'Saved ${days ~/ 30} months ago';
}

/// The one-line "Offline" strip with a Retry. It is also the collapsed
/// card of Home's sheet while offline.
class MapHomeOfflineStrip extends StatelessWidget {
  const MapHomeOfflineStrip({super.key, required this.board});

  final MapHomeBoardData board;

  @override
  Widget build(BuildContext context) {
    final scope = MapHomeOfflineScope.maybeOf(context);
    final saved = mapHomeSavedLabel(board.savedAt, DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 20,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "You're offline",
                  style: AppTextStyles.headingForeground,
                ),
                Text(
                  saved ?? 'No saved progress on this phone yet',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: scope == null || scope.retrying ? null : scope.onRetry,
            child: scope?.retrying == true
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// The expanded sheet's body while offline: what still works, what needs a
/// connection.
class MapHomeOfflineBody extends StatelessWidget {
  const MapHomeOfflineBody({super.key, required this.board});

  final MapHomeBoardData board;

  @override
  Widget build(BuildContext context) {
    final pending = board.countyBadges
        .where((b) => b.state == MapHomeCountyBadgeState.pending)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pending == 0
                ? 'Counties you visit are still detected and will be saved '
                      'when you reconnect.'
                : '$pending ${pending == 1 ? 'county is' : 'counties are'} '
                      'waiting to be saved. They will sync when you '
                      'reconnect.',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Reconnect to see places near you and suggestions for your '
            'next county.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
