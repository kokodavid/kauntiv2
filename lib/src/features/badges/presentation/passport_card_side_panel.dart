import 'package:flutter/material.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../../design/app_colors.dart';
import '../domain/passport_level.dart';
import 'passport_kenya_map.dart';
import 'passport_text.dart';

/// The map / picture panel. Tapping it flips between the two; two small
/// dots show which one is up.
class PassportCardSidePanel extends StatelessWidget {
  const PassportCardSidePanel({
    required this.showPhoto,
    required this.avatarUrl,
    required this.name,
    required this.levels,
    required this.onToggle,
  });

  final bool showPhoto;
  final String? avatarUrl;
  final String? name;
  final Map<int, PassportLevel> levels;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: showPhoto
          ? 'Profile picture. Tap to show the map of Kenya'
          : 'Map of Kenya. Tap to show your profile picture',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: Column(
          children: [
            SizedBox(
              height: 118,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: showPhoto
                    ? _Photo(
                        key: const ValueKey('photo'),
                        url: avatarUrl,
                        name: name,
                      )
                    : KeyedSubtree(
                        key: const ValueKey('map'),
                        child: SizedBox.expand(
                          child: PassportKenyaMap(levels: levels),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Dot(active: !showPhoto),
                const SizedBox(width: 5),
                _Dot(active: showPhoto),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: active ? 14 : 5,
    height: 5,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(3),
      color: active ? AppColors.accent : AppColors.trackInactive,
    ),
  );
}

class _Photo extends StatelessWidget {
  const _Photo({super.key, required this.url, required this.name});

  final String? url;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final hasPicture = url != null && url!.isNotEmpty;
    final initial = (name == null || name!.isEmpty)
        ? '?'
        : name!.characters.first.toUpperCase();
    return Center(
      child: Container(
        width: 108,
        height: 108,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: hasPicture
              ? Image(
                  image: appNetworkImage(url!, cacheWidth: 240),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _Initial(initial: initial),
                )
              : _Initial(initial: initial),
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFDCEBFA),
    child: Center(
      child: Text(
        initial,
        style: passportText(
          38,
          weight: FontWeight.w700,
          color: AppColors.accent,
        ),
      ),
    ),
  );
}
