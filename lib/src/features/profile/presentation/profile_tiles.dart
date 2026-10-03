import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';

abstract final class ProfilePalette {
  static const surface = Color(0xFFEAF4FF);
  static const border = Color(0xFFD5E7FA);
}

enum ProfileTileStyle { row, surface, dark }

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.accent,
      ),
    ),
  );
}

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.style = ProfileTileStyle.row,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final ProfileTileStyle style;

  @override
  Widget build(BuildContext context) {
    if (style == ProfileTileStyle.row) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.accent),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      );
    }

    final dark = style == ProfileTileStyle.dark;
    final foreground = dark ? Colors.white : AppColors.foreground;
    final muted = dark ? Colors.white70 : AppColors.mutedForeground;
    // Dark tiles sit on a near-black Ink, so a white icon reads clearly.
    // Surface tiles sit on the pale `ProfilePalette.surface` blue, so the
    // icon itself needs to carry the solid accent color -- a white icon
    // there (the previous bug) all but disappeared against the light fill.
    final iconColor = dark ? Colors.white : AppColors.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: dark ? null : Border.all(color: ProfilePalette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dark ? AppColors.accent : ProfilePalette.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
