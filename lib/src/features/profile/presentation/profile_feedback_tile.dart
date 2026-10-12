import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/connectivity_provider.dart';
import '../../feedback/application/feedback_providers.dart';
import '../../feedback/application/feedback_submit_providers.dart';
import 'profile_tiles.dart';

/// Profile's "Beta feedback" entry. Only testers with an active seat see
/// it; for everyone else it takes no space. Being back online also sends
/// any report that was written without a connection.
class ProfileFeedbackTile extends ConsumerWidget {
  const ProfileFeedbackTile({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(connectivityProvider.select((s) => s.isOffline), (was, now) {
      if (was == true && !now) {
        unawaited(ref.read(feedbackOutboxSyncProvider.notifier).flush());
      }
    });
    final isTester = ref.watch(hasTesterSeatProvider).value ?? false;
    if (!isTester) return const SizedBox.shrink();
    final waiting = ref.watch(feedbackOutboxSyncProvider).value ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ProfileTile(
        icon: Icons.chat_bubble_outline,
        title: 'Beta feedback',
        subtitle: waiting > 0
            ? '$waiting waiting to send'
            : 'Report a bug or share an idea',
        style: ProfileTileStyle.surface,
        onTap: onOpen,
      ),
    );
  }
}
