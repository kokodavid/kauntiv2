import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import 'profile_tiles.dart';

/// Shared building blocks for the Settings screen's sections, following
/// the same "small pieces, one file" pattern as `profile_tiles.dart`.

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.mutedForeground,
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: ProfilePalette.border),
    ),
    child: Column(children: children),
  );
}

/// A title/subtitle pair with a trailing [Switch], used by Notifications
/// and the Privacy section's "Show me on leaderboards".
class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.divider = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool divider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (divider) const Divider(height: 1, color: Color(0xFFF1F1F3)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.accent,
            ),
          ],
        ),
      ),
    ],
  );
}

/// A row that opens something else: a sheet, an external link, or (with
/// [danger]) a destructive action. Used across Account and Developer.
class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.divider = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  final bool divider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (divider) const Divider(height: 1, color: Color(0xFFF1F1F3)),
      ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: danger ? AppColors.danger : AppColors.foreground,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
        trailing:
            trailing ??
            (onTap != null ? const Icon(Icons.chevron_right) : null),
      ),
    ],
  );
}

/// A row of mutually-exclusive pill choices (map visibility, detection
/// mode, side-quest radius). Wraps when there isn't room for one line.
class SettingsSegmented<T> extends StatelessWidget {
  const SettingsSegmented({
    super.key,
    required this.options,
    required this.labelOf,
    required this.value,
    required this.onChanged,
  });

  final List<T> options;
  final String Function(T) labelOf;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final option in options)
        _Pill(
          label: labelOf(option),
          selected: option == value,
          onTap: () => onChanged(option),
        ),
    ],
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.accent : const Color(0xFFF5F6F8),
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.mutedForeground,
          ),
        ),
      ),
    ),
  );
}
