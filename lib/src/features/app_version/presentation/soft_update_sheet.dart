import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../application/app_update_providers.dart';
import '../domain/update_notes.dart';
import 'update_copy.dart';
import 'update_notes_list.dart';
import 'update_widgets.dart';

/// Opens the soft update sheet. "Later", the scrim and swiping down all mean
/// the same thing: stop offering it for a week (the Settings row stays).
Future<void> showSoftUpdateSheet(
  BuildContext context,
  WidgetRef ref, {
  bool startExpanded = false,
}) async {
  final controller = ref.read(appUpdateControllerProvider.notifier);
  final toastContext = context;
  final choice = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: AppColors.updateScrim,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _SoftUpdateSheet(startExpanded: startExpanded),
  );
  if (choice == true) {
    if (!toastContext.mounted) return;
    showAppToast(
      toastContext,
      variant: AppToastVariant.neutral,
      icon: Icons.info_outline_rounded,
      title: 'Opening ${updateStoreName()}…',
      message: "Come back when it's done.",
      duration: const Duration(seconds: 4),
    );
    await controller.openStore();
    return;
  }
  await controller.snoozeSoft();
  if (!toastContext.mounted || startExpanded) return;
  showAppToast(
    toastContext,
    variant: AppToastVariant.neutral,
    icon: Icons.info_outline_rounded,
    title: 'Update anytime in Settings',
    message: "We won't ask again for a while.",
    duration: const Duration(seconds: 4),
  );
}

class _SoftUpdateSheet extends ConsumerStatefulWidget {
  const _SoftUpdateSheet({required this.startExpanded});

  final bool startExpanded;

  @override
  ConsumerState<_SoftUpdateSheet> createState() => _SoftUpdateSheetState();
}

class _SoftUpdateSheetState extends ConsumerState<_SoftUpdateSheet> {
  late bool _expanded = widget.startExpanded;

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(appUpdateControllerProvider);
    if (policy == null) return const SizedBox(height: 120);
    final notes = parseUpdateNotes(policy.releaseNotes);
    final store = updateStoreName();
    final noLink = policy.storeUrl == null;
    final version = policy.latestVersion;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.sheetGrabber,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const UpdateAppIcon(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A new version is ready',
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: AppColors.buttonForeground,
                        ),
                      ),
                      if (version != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          updateVersionLabel(version),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                "WHAT'S NEW",
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.92,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: _expanded
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 420),
                        child: SingleChildScrollView(
                          child: UpdateNotesList(
                            items: notes,
                            dot: 5,
                            gap: 8,
                          ),
                        ),
                      )
                    : UpdateNotesList(
                        items: notes,
                        dot: 5,
                        gap: 8,
                        collapsedHeight: 60,
                      ),
              ),
              UpdateNotesToggle(
                expanded: _expanded,
                moreLabel: 'See more',
                lessLabel: 'See less',
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ],
            if (noLink) ...[
              const SizedBox(height: 8),
              UpdateInlineMessage(
                tone: UpdateMessageTone.info,
                icon: Icons.schedule_rounded,
                title: 'Almost ready',
                body:
                    'Version $version is on its way to $store. '
                    "We'll show it in Settings when it's ready.",
              ),
            ],
            const SizedBox(height: 14),
            UpdateButton(
              label: noLink ? 'Coming to the store soon' : 'Update',
              height: 52,
              style: noLink
                  ? UpdateButtonStyle.inactive
                  : UpdateButtonStyle.filled,
              onPressed: noLink ? null : () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppColors.bodyText,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Later'),
            ),
          ],
        ),
      ),
    );
  }
}
