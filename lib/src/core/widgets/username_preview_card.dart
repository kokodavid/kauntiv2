import 'package:flutter/material.dart';

import '../../design/app_colors.dart';

/// The dark card at the top of the username picker: the name as it will
/// appear, the account's avatar, and a refresh button for four new
/// suggestions. It shows
/// the picked (or typed) name, or the current one while nothing is picked.
class UsernamePreviewCard extends StatelessWidget {
  const UsernamePreviewCard({
    super.key,
    required this.handle,
    required this.caption,
    required this.avatar,
    required this.onRefresh,
  });

  final String handle;
  final String caption;
  final Widget avatar;

  /// Fetch four new suggestions; null while that is already under way.
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.buttonForeground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox.square(dimension: 36, child: ClipOval(child: avatar)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@$handle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'More names',
            excludeSemantics: true,
            onTap: onRefresh,
            child: Material(
              color: Colors.white.withValues(alpha: 0.12),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRefresh,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
