import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../auth/application/auth_providers.dart';
import '../application/place_photos_banner_controller.dart';

/// A dismissable nudge above the photo strip: if you've been to this
/// place, your photos help improve what the app shows for it. Dismiss
/// is remembered on this phone per account, the same local-only pattern
/// as the Home "Tell us what you like" card -- once closed, it stays
/// closed everywhere, not just on this place.
class PlacePhotosAddNudgeBanner extends ConsumerStatefulWidget {
  const PlacePhotosAddNudgeBanner({super.key, required this.onAdd});

  /// Opens the same add-photo flow as the strip's other entry points.
  final VoidCallback onAdd;

  @override
  ConsumerState<PlacePhotosAddNudgeBanner> createState() =>
      _PlacePhotosAddNudgeBannerState();
}

class _PlacePhotosAddNudgeBannerState
    extends ConsumerState<PlacePhotosAddNudgeBanner> {
  bool _loading = true;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final owner = ref.read(currentUserIdProvider)();
    final dismissed = owner == null
        ? false
        : await placePhotosBannerController.isDismissed(owner);
    if (mounted) {
      setState(() {
        _dismissed = dismissed;
        _loading = false;
      });
    }
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    final owner = ref.read(currentUserIdProvider)();
    if (owner != null) await placePhotosBannerController.dismiss(owner);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _dismissed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.infoTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              size: 18,
              color: AppColors.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: widget.onAdd,
                child: Text.rich(
                  TextSpan(
                    text: "Been here? ",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.foreground,
                    ),
                    children: [
                      TextSpan(
                        text: 'Add your photos',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(
                        text: ' to improve the gallery for this place.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                tooltip: 'Dismiss',
                padding: EdgeInsets.zero,
                onPressed: _dismiss,
                color: AppColors.mutedForeground,
                icon: const Icon(Icons.close, size: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
