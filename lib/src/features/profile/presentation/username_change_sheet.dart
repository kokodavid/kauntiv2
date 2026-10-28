import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/username_providers.dart';
import 'username_chooser_section.dart';

/// A small sheet for choosing a username when a feature needs one (the
/// photo prompt). Edit Profile shows the same picker inline instead of
/// opening this.
class UsernameChangeSheet extends ConsumerStatefulWidget {
  const UsernameChangeSheet({super.key, this.isFirstChoice = false});

  /// The account has no chosen username yet (a feature asked for one), so
  /// the sheet says "Choose" and there is no 30 day note.
  final bool isFirstChoice;

  /// True when a new username was saved.
  static Future<bool> show(
    BuildContext context, {
    bool isFirstChoice = false,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UsernameChangeSheet(isFirstChoice: isFirstChoice),
    );
    return saved ?? false;
  }

  @override
  ConsumerState<UsernameChangeSheet> createState() =>
      _UsernameChangeSheetState();
}

class _UsernameChangeSheetState extends ConsumerState<UsernameChangeSheet> {
  Future<void> _save() async {
    final saved = await ref.read(usernameChooserProvider.notifier).save();
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usernameChooserProvider);
    final canSave = widget.isFirstChoice
        ? state.canSave
        : state.canSave && state.userPicked;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isFirstChoice
                      ? 'Choose a username'
                      : 'Change username',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  onPressed: canSave ? () => unawaited(_save()) : null,
                  child: state.isSaving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.isFirstChoice
                  ? 'Credited on your photos and trips, never your real name.'
                  : 'You can change it once every 30 days.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            UsernameChooserSection(requirePick: !widget.isFirstChoice),
          ],
        ),
      ),
    );
  }
}
