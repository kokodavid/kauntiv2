import 'package:flutter/material.dart';

import '../../../core/widgets/offline_screen.dart';
import '../../../design/app_colors.dart';
import 'explore_header.dart';
import 'explore_styles.dart';

class ExploreStateNotice extends StatelessWidget {
  const ExploreStateNotice({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: ExploreStyles.cardDecoration,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.mutedForeground),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ExploreStyles.insightTitle),
              const SizedBox(height: 3),
              Text(message, style: ExploreStyles.emptyBody),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Explore with nothing loaded and nothing saved: the title stays, the body
/// is the shared full-screen offline state. It reloads by itself when the
/// connection returns.
class ExploreOfflineState extends StatelessWidget {
  const ExploreOfflineState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: ExploreTopBar(),
      ),
      Expanded(
        child: OfflineScreen(
          key: const Key('explore-offline-screen'),
          message:
              'Counties and places load from the internet. Check your data '
              'or Wi-Fi, then try again.',
          onRetry: onRetry,
        ),
      ),
    ],
  );
}
