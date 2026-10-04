import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_media_picker.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../design/app_colors.dart';
import '../application/public_profile_providers.dart';
import '../domain/public_profile.dart';
import 'profile_text_field.dart';

/// Change photo, display name and handle -- all three are already
/// owner-writable on `quest_public_profiles` (see
/// `SupabasePublicProfileRepository`'s doc comment), so this sheet talks
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
  late final _handleController = TextEditingController(
    text: widget.profile.handle,
  );
  String? _avatarUrl;
  bool _savingPhoto = false;
  bool _saving = false;
  String? _handleError;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.profile.avatarUrl;
    _handleController.addListener(() => setState(() => _handleError = null));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  bool get _handleLooksValid =>
      isValidHandle(_handleController.text.trim().toLowerCase());
  bool get _handleUnchanged =>
      _handleController.text.trim().toLowerCase() == widget.profile.handle;

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
    setState(() => _savingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final extension = picked.path.split('.').last.toLowerCase();
      final url = await repository.uploadAvatar(
        bytes,
        extension: extension == 'jpeg' ? 'jpg' : extension,
      );
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
    final handle = _handleController.text.trim().toLowerCase();
    if (!_handleLooksValid) {
      setState(() => _handleError = 'Invalid');
      return;
    }
    setState(() => _saving = true);
    try {
      await repository.update(
        displayName: name.isEmpty ? null : name,
        handle: _handleUnchanged ? null : handle,
      );
      ref.invalidate(myPublicProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } on HandleAlreadyTakenException {
      if (mounted) {
        setState(() => _handleError = 'That handle is already taken');
      }
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

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: SafeArea(
      top: false,
      child: Padding(
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
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
                      : const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.accent,
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? appNetworkImage(_avatarUrl!)
                      : null,
                  child: _savingPhoto
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : (_avatarUrl == null || _avatarUrl!.isEmpty)
                      ? const Icon(Icons.image_outlined, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                  onPressed: _savingPhoto
                      ? null
                      : () => unawaited(_changePhoto()),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Change photo'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ProfileTextField(
              label: 'Display name',
              controller: _nameController,
              maxLength: 80,
            ),
            const SizedBox(height: 10),
            ProfileTextField(
              label: 'Handle',
              controller: _handleController,
              maxLength: 30,
              prefixText: '@',
              errorText: _handleError ?? (_handleLooksValid ? null : 'Invalid'),
              suffixText: _handleUnchanged ? 'Current' : null,
              helperCaption:
                  'Shown on Ranks and to Friends when they arrive. Letters, '
                  'numbers, hyphens and underscores.',
            ),
          ],
        ),
      ),
    ),
  );
}
