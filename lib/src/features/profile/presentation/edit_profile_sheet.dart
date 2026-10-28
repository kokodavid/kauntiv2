import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_media_picker.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../design/app_colors.dart';
import '../application/public_profile_providers.dart';
import '../application/username_providers.dart';
import '../domain/public_profile.dart';
import 'avatar_crop_screen.dart';
import 'avatar_viewer.dart';
import 'profile_text_field.dart';
import 'username_chooser_section.dart';

/// Change photo, display name and username here. The username is picked
/// from suggestion pills (or edited) right in the sheet; it goes through the
/// server's rules and a 30 day limit when Save is tapped. Photo and name are
/// owner-writable on `quest_public_profiles`, so this sheet talks
/// to the repository directly rather than through a notifier: there's no
/// shared state another screen needs, just a save action and a result.
class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key, required this.profile});

  final PublicProfile profile;

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final _nameController = TextEditingController(
    text: widget.profile.displayName,
  );
  String? _avatarUrl;
  bool _savingPhoto = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.profile.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final repository = ref.read(publicProfileRepositoryProvider);
    if (repository == null) return;
    final picked = await AppMediaPicker.pickImage(
      source: AppImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final raw = await picked.readAsBytes();
    if (!mounted) return;
    // Frame it first; cancelling leaves the current photo as it was.
    final bytes = await AvatarCropScreen.open(context, raw);
    if (bytes == null || !mounted) return;
    setState(() => _savingPhoto = true);
    try {
      final url = await repository.uploadAvatar(bytes, extension: 'png');
      if (mounted) setState(() => _avatarUrl = url);
      ref.invalidate(myPublicProfileProvider);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't update your photo. Try again."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _save() async {
    final repository = ref.read(publicProfileRepositoryProvider);
    if (repository == null) return;
    final name = _nameController.text.trim();
    setState(() => _saving = true);
    try {
      // Username first: if the server refuses it (taken, or changed too
      // recently) the reason shows under the pills and nothing else saves.
      final picker = ref.read(usernameChooserProvider);
      final newHandle = picker.userPicked ? picker.chosen : null;
      if (newHandle != null && newHandle != _currentHandle) {
        final saved = await ref.read(usernameChooserProvider.notifier).save();
        if (!saved) return;
      }
      if (name.isNotEmpty && name != widget.profile.displayName) {
        await repository.update(displayName: name);
      }
      ref.invalidate(myPublicProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save. Try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _currentHandle =>
      ref.read(myPublicProfileProvider).value?.handle ?? widget.profile.handle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit profile',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: _saving || _savingPhoto
                      ? null
                      : () => unawaited(_save()),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(),
                const SizedBox(width: 14),
                Expanded(
                  child: ProfileTextField(
                    label: 'Display name',
                    controller: _nameController,
                    maxLength: 80,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Only you and Kaunti47 staff see your display name.',
              style: TextStyle(fontSize: 11.5, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.listDivider),
            const SizedBox(height: 14),
             UsernameChooserSection(
              requirePick: true,
              showHeader: true,
              inputFirst: true,
              initialText: widget.profile.handle,
            ),
          ],
        ),
      ),
    ),
  );

  /// The avatar with a camera badge: the badge changes the photo, tapping
  /// the photo itself opens it full size.
  Widget _avatar() {
    final url = _avatarUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    return SizedBox.square(
      dimension: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: hasPhoto
                ? () => unawaited(AvatarViewer.show(context, url))
                : null,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.accent,
              backgroundImage: hasPhoto ? appNetworkImage(url) : null,
              child: _savingPhoto
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : hasPhoto
                  ? null
                  : const Icon(Icons.image_outlined, color: Colors.white),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Semantics(
              button: true,
              label: 'Change photo',
              excludeSemantics: true,
              onTap: _savingPhoto ? null : () => unawaited(_changePhoto()),
              child: GestureDetector(
                onTap: _savingPhoto ? null : () => unawaited(_changePhoto()),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.buttonForeground,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 12,
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
