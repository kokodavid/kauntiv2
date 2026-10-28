import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/username_picker.dart';
import '../../../design/app_colors.dart';
import '../application/public_profile_providers.dart';
import '../application/username_providers.dart';
import '../domain/username.dart';
import 'username_field_status.dart';

/// The username picker bound to [usernameChooserProvider]: suggestion
/// pills, "More", and "Edit selected name". Used inline by Edit Profile, by
/// the photo prompt's sheet and by setup. It owns only the text controller;
/// whoever hosts it reads the provider for Save / Continue.
///
/// With [showHeader] it starts with a small "Username · seen by explorers"
/// line and the current name.
///
/// With [requirePick] the pre-selected first suggestion is hidden until the
/// user touches something, so a host that saves on a button (Edit Profile)
/// cannot swap the name by accident.
class UsernameChooserSection extends ConsumerStatefulWidget {
  const UsernameChooserSection({
    super.key,
    this.requirePick = false,
    this.showHeader = false,
    this.inputFirst = false,
    this.initialText,
  });

  final bool requirePick;
  final bool showHeader;

  /// The field comes first and the suggestions after it. Picking a
  /// suggestion then also fills the field.
  final bool inputFirst;

  /// What the field holds to begin with (the current username in Edit
  /// Profile). It is not a change until the user touches something.
  final String? initialText;

  @override
  ConsumerState<UsernameChooserSection> createState() =>
      _UsernameChooserSectionState();
}

class _UsernameChooserSectionState
    extends ConsumerState<UsernameChooserSection> {
  late final _controller = TextEditingController(
    text:
        widget.initialText ??
        (widget.inputFirst
            ? ref.read(myPublicProfileProvider).value?.handle
            : null),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _editSelected() {
    final selected = ref.read(usernameChooserProvider).selected ?? '';
    _controller.value = TextEditingValue(
      text: selected,
      selection: TextSelection.collapsed(offset: selected.length),
    );
    ref.read(usernameChooserProvider.notifier).editSelected();
  }

  @override
  Widget build(BuildContext context) {
    // The profile can arrive after this opens (a brand-new account): fill
    // the field with the current name then, unless the user already typed.
    ref.listen(myPublicProfileProvider, (_, next) {
      final handle = next.value?.handle;
      if (widget.inputFirst &&
          handle != null &&
          _controller.text.isEmpty &&
          !ref.read(usernameChooserProvider).userPicked) {
        _controller.text = handle;
      }
    });
    final state = ref.watch(usernameChooserProvider);
    final chooser = ref.read(usernameChooserProvider.notifier);
    final (status, message) = usernameFieldStatus(state);
    final showSelection = !widget.requirePick || state.userPicked;
    final profile = ref.watch(myPublicProfileProvider).value;
    final current = profile?.handle;
    final typed = normalizeUsername(state.customText);
    final shown = state.isCustom
        ? (typed.isEmpty ? null : typed)
        : (showSelection ? state.selected : null);
    final isNew = shown != null && shown != current;
    final picker = UsernamePicker(
      previewHandle: profile == null || widget.inputFirst
          ? null
          : (shown ?? current),
      previewCaption: isNew
          ? 'Was @$current · can be changed once every 30 days'
          : 'Your username · can be changed once every 30 days',
      previewAvatar: profile == null || widget.inputFirst
          ? null
          : _Avatar(url: profile.avatarUrl, name: profile.displayName),
      suggestions: state.suggestions,
      isLoading: state.isLoading,
      loadFailed: state.loadFailed,
      selected: showSelection ? state.selected : null,
      isCustom: state.isCustom,
      customController: _controller,
      customStatus: status,
      customMessage: message,
      errorMessage: state.error,
      inputFirst: widget.inputFirst,
      onSelect: (handle) {
        if (widget.inputFirst) {
          _controller.value = TextEditingValue(
            text: handle,
            selection: TextSelection.collapsed(offset: handle.length),
          );
        }
        chooser.select(handle);
      },
      onMore: () => unawaited(chooser.loadSuggestions()),
      onEditSelected: _editSelected,
      onCustomChanged: chooser.onCustomChanged,
    );
    if (!widget.showHeader) return picker;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'USERNAME · SEEN BY EXPLORERS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.mutedForeground,
              ),
            ),
            if (current != null && !widget.inputFirst)
              Text(
                'Now @$current',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        picker,
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url != null && url.isNotEmpty) {
      return Image(image: appNetworkImage(url), fit: BoxFit.cover);
    }
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return ColoredBox(
      color: AppColors.accent,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
