import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/notifications_prompt.dart';

/// Home's "Know when you cross a line" card, for people whose phone does
/// not allow notifications (they never saw the setup step, or said "Not
/// now"). It hides itself, taking no space, unless
/// [notificationsPromptProvider] says it is due. The button asks the phone
/// once, then sends the person to the app's settings; coming back with
/// notifications on removes the card.
class NotificationsPromptCard extends ConsumerStatefulWidget {
  const NotificationsPromptCard({super.key, required this.onOpenSettings});

  /// Opens the phone's settings for this app.
  final Future<void> Function() onOpenSettings;

  @override
  ConsumerState<NotificationsPromptCard> createState() =>
      _NotificationsPromptCardState();
}

class _NotificationsPromptCardState
    extends ConsumerState<NotificationsPromptCard>
    with WidgetsBindingObserver {
  static const _background = Color(0xFFEAF4FF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationsPromptProvider.notifier).recheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(notificationsPromptProvider).value != true) {
      return const SizedBox.shrink();
    }
    final prompt = ref.read(notificationsPromptProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    Icons.notifications_none_outlined,
                    size: 22,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Know when you cross a line',
                    style: AppTextStyles.listItemTitle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    tooltip: 'Dismiss',
                    padding: EdgeInsets.zero,
                    onPressed: () => unawaited(prompt.dismiss()),
                    color: AppColors.mutedForeground,
                    icon: const Icon(Icons.close, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Get a heads-up the moment you enter a new county, '
                      'even when the app is closed.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => unawaited(
                        prompt.turnOn(
                          openSettings: () =>
                              unawaited(widget.onOpenSettings()),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.accentForeground,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Turn on',
                        style: AppTextStyles.buttonLabel.copyWith(
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
