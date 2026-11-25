import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import 'username_own_field.dart';
import 'username_pills.dart';
import 'username_preview_card.dart';

export 'username_own_field.dart' show UsernameFieldStatus;

/// Username suggestions as pills, a "Show me more" pill, and below them
/// "Edit selected name" (or "Write my own" when nothing is picked), which
/// opens a field with the server's verdict as the user types. Shared by
/// setup, Edit Profile and the photo prompt. It holds no state of its own:
/// the caller owns the controller and passes in everything it shows.
class UsernamePicker extends StatelessWidget {
  const UsernamePicker({
    super.key,
    required this.suggestions,
    required this.isLoading,
    required this.selected,
    required this.isCustom,
    required this.customController,
    required this.customStatus,
    required this.customMessage,
    required this.onSelect,
    required this.onMore,
    required this.onEditSelected,
    required this.onCustomChanged,
    this.loadFailed = false,
    this.errorMessage,
    this.previewHandle,
    this.previewCaption,
    this.previewAvatar,
    this.inputFirst = false,
  });

  final List<String> suggestions;
  final bool isLoading;
  final bool loadFailed;
  final String? selected;
  final bool isCustom;
  final TextEditingController customController;
  final UsernameFieldStatus customStatus;
  final String? customMessage;

  /// A save error shown under everything (rate limit, no connection).
  final String? errorMessage;

  final ValueChanged<String> onSelect;
  final VoidCallback onMore;

  /// Opens the field, filled with the picked suggestion (or empty).
  final VoidCallback onEditSelected;
  final ValueChanged<String> onCustomChanged;

  /// The dark preview card above the grid: the name as it will appear. Shown
  /// when [previewHandle], [previewCaption] and [previewAvatar] are all set.
  final String? previewHandle;
  final String? previewCaption;
  final Widget? previewAvatar;

  /// Put the field first and the suggestions after it ("Or pick one"), for
  /// people who come with a name in mind (Edit Profile). Otherwise the
  /// suggestions come first and the field opens from "Edit selected name"
  /// (setup, where most people have no name yet).
  final bool inputFirst;

  Widget _suggestionGrid() {
    if (isLoading && suggestions.isEmpty) return const _Placeholder();
    if (loadFailed && suggestions.isEmpty) {
      return const Text(
        "Couldn't load suggestions. Check your connection, or write your "
        'own.',
        style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
      );
    }
    return _Grid(
      children: [
        for (final handle in suggestions)
          UsernamePill(
            label: '@$handle',
            isSelected: !isCustom && handle == selected,
            onTap: () => onSelect(handle),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (previewHandle != null &&
            previewCaption != null &&
            previewAvatar != null) ...[
          UsernamePreviewCard(
            handle: previewHandle!,
            caption: previewCaption!,
            avatar: previewAvatar!,
            onRefresh: isLoading ? null : onMore,
          ),
          const SizedBox(height: 10),
        ],
        if (inputFirst) ...[
          UsernameOwnField(
            controller: customController,
            status: customStatus,
            message: customMessage,
            onChanged: onCustomChanged,
            autofocus: false,
            hint: 'Type your own username',
            idleMessage: 'You can change your username once every 30 days.',
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OR PICK ONE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.mutedForeground,
                ),
              ),
              Semantics(
                button: true,
                label: 'More names',
                excludeSemantics: true,
                onTap: isLoading ? null : onMore,
                child: InkResponse(
                  onTap: isLoading ? null : onMore,
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: isLoading
                          ? AppColors.mutedForeground
                          : AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          _suggestionGrid(),
        ] else ...[
          _suggestionGrid(),
          const SizedBox(height: 6),
          if (isCustom)
            UsernameOwnField(
              controller: customController,
              status: customStatus,
              message: customMessage,
              onChanged: onCustomChanged,
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: onEditSelected,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(
                  selected == null ? 'Write my own' : 'Edit selected name',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

/// Two columns of equal width, 8 apart.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: children[i]),
            const SizedBox(width: 8),
            Expanded(
              child: i + 1 < children.length
                  ? children[i + 1]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < children.length) rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => _Grid(
    children: [
      for (var i = 0; i < 4; i++)
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.secondaryFill.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
    ],
  );
}
