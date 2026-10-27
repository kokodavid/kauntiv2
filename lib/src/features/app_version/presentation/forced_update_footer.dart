import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../domain/app_update_policy.dart';
import 'forced_update_screen.dart';
import 'update_copy.dart';
import 'update_widgets.dart';

/// Pinned footer of the forced screen: optional inline message, the single
/// action, and a caption. The top rule shows only while content scrolls.
class ForcedUpdateFooter extends StatelessWidget {
  const ForcedUpdateFooter({
    super.key,
    required this.policy,
    required this.busy,
    required this.problem,
    required this.stillNoLink,
    required this.raised,
    required this.onPrimary,
  });

  final AppUpdatePolicy policy;
  final bool busy;
  final UpdateProblem problem;
  final bool stillNoLink;
  final bool raised;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final store = updateStoreName();
    final noLink = policy.storeUrl == null;
    final version = policy.latestVersion ?? policy.requiredVersion;
    final hasProblem = problem != UpdateProblem.none;
    final label = hasProblem
        ? (busy ? 'Trying again…' : 'Try again')
        : noLink
        ? (busy ? 'Checking…' : 'Check again')
        : (busy ? 'Opening $store…' : 'Update now');
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        border: Border(
          top: BorderSide(
            color: raised ? AppColors.softDivider : Colors.transparent,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (problem == UpdateProblem.offline) ...[
            const UpdateInlineMessage(
              tone: UpdateMessageTone.warning,
              icon: Icons.wifi_off_rounded,
              title: "You're offline",
              body: 'Connect to the internet, then try again.',
            ),
            const SizedBox(height: 10),
          ] else if (problem == UpdateProblem.storeFailed) ...[
            UpdateInlineMessage(
              tone: UpdateMessageTone.warning,
              icon: Icons.open_in_new_rounded,
              title: "Couldn't open the store",
              body: 'Try again, or open $store and search for Kaunti47.',
            ),
            const SizedBox(height: 10),
          ] else if (noLink) ...[
            UpdateInlineMessage(
              tone: UpdateMessageTone.info,
              icon: Icons.schedule_rounded,
              title: 'Almost ready',
              body: stillNoLink
                  ? 'Still on its way to $store. We checked just now. '
                        'Try again in a little while.'
                  : 'Version $version is on its way to $store. '
                        'Check again in a little while.',
            ),
            const SizedBox(height: 10),
          ],
          UpdateButton(
            label: label,
            busy: busy,
            style: noLink && !hasProblem
                ? UpdateButtonStyle.outlined
                : UpdateButtonStyle.filled,
            onPressed: onPrimary,
          ),
          const SizedBox(height: 10),
          Text(
            noLink
                ? 'You have version ${policy.currentVersion}'
                : 'Opens $store · You have ${policy.currentVersion}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
