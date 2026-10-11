import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/services/app_media_picker.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../domain/feedback_models.dart';

/// Screenshots and a short recording, up to three files. Picked from the
/// photo library: take the screenshot first, then attach it.
class FeedbackAttachmentsField extends StatelessWidget {
  const FeedbackAttachmentsField({
    super.key,
    required this.files,
    required this.onChanged,
    this.enabled = true,
  });

  final List<FeedbackAttachmentFile> files;
  final ValueChanged<List<FeedbackAttachmentFile>> onChanged;
  final bool enabled;

  bool get _full => files.length >= FeedbackAttachmentFile.maxPerReport;

  Future<void> _addImage(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await AppMediaPicker.pickImage(
      source: AppImageSource.gallery,
      maxWidth: 2200,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _accept(messenger, picked.path, await picked.length());
  }

  Future<void> _addVideo(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await AppMediaPicker.pickVideo(
      maxDuration: const Duration(minutes: 2),
    );
    if (picked == null) return;
    await _accept(messenger, picked.path, await picked.length());
  }

  Future<void> _accept(
    ScaffoldMessengerState messenger,
    String path,
    int size,
  ) async {
    final mime = FeedbackAttachmentFile.mimeForPath(path);
    if (mime == null) {
      _say(messenger, 'That file type is not supported. Use JPG, PNG, MP4 or MOV.');
      return;
    }
    if (size > FeedbackAttachmentFile.maxBytes) {
      _say(messenger, 'That file is over 50 MB. Choose a shorter recording.');
      return;
    }
    onChanged([
      ...files,
      FeedbackAttachmentFile(path: path, mimeType: mime, sizeBytes: size),
    ]);
  }

  void _say(ScaffoldMessengerState messenger, String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final file in files)
                  _Thumb(
                    file: file,
                    onRemove: enabled
                        ? () => onChanged([
                            for (final f in files)
                              if (f != file) f,
                          ])
                        : null,
                  ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _AddButton(
              icon: Icons.image_outlined,
              label: 'Add screenshot',
              onTap: enabled && !_full ? () => unawaited(_addImage(context)) : null,
            ),
            _AddButton(
              icon: Icons.videocam_outlined,
              label: 'Add recording',
              onTap: enabled && !_full ? () => unawaited(_addVideo(context)) : null,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Up to ${FeedbackAttachmentFile.maxPerReport} files, 50 MB each. '
          'Only the team sees them.',
          style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? AppColors.mutedForeground : AppColors.accent;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: AppTextStyles.chipLabel.copyWith(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.file, required this.onRemove});

  final FeedbackAttachmentFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 76,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: file.isVideo
                ? const ColoredBox(
                    color: AppColors.secondaryFill,
                    child: Icon(Icons.videocam, color: AppColors.mutedForeground),
                  )
                : Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    cacheWidth: 200,
                    errorBuilder: (context, error, stack) => const ColoredBox(
                      color: AppColors.secondaryFill,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
          if (onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xCC000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
