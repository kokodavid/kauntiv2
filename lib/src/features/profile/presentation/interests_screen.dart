import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/choice_tile_grid.dart';
import '../../../core/widgets/interest_icons.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/interests_providers.dart';
import '../domain/place_interest.dart';

/// Interests, on its own screen (Settings > Interests, and the Home card's
/// "Pick interests"): the same tiles as setup step 2, minus the progress,
/// so an existing user never sees a step count. Save writes the picks;
/// "Clear all" only empties the selection until Save.
class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  /// Null until the saved picks have loaded and been copied in.
  List<PlaceInterest>? _picks;
  bool _saving = false;

  void _toggle(PlaceInterest interest) {
    final current = _picks ?? const <PlaceInterest>[];
    setState(() {
      _picks = current.contains(interest)
          ? [
              for (final i in current)
                if (i != interest) i,
            ]
          : PlaceInterest.fromKeys([...current.map((i) => i.key), interest.key]);
    });
  }

  Future<void> _save() async {
    final picks = _picks;
    if (picks == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(myInterestsProvider.notifier).save(picks);
      // Answered: the Home card has nothing left to ask.
      unawaited(ref.read(interestsPromptProvider.notifier).dismiss());
      if (mounted) unawaited(Navigator.of(context).maybePop());
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(myInterestsProvider);
    final loaded = saved.value;
    if (_picks == null && loaded != null) _picks = loaded.interests;
    final picks = _picks;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Interests',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        titleSpacing: 12,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 68,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: AppBackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: picks == null
            ? const Center(
                child: AppProgressIndicator(
                  color: AppColors.accent,
                  radius: 14,
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What do you like to see?',
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 18,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'For you leans toward these, and still shows '
                            'other places too.',
                            style: AppTextStyles.bodyMuted.copyWith(
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ChoiceTileGrid<PlaceInterest>(
                            options: PlaceInterest.values,
                            selected: picks,
                            labelOf: (interest) => interest.label,
                            iconOf: (interest) => interestIconForKey(interest.key),
                            onToggle: _toggle,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _Footer(
                    saving: _saving,
                    canClear: picks.isNotEmpty,
                    onSave: () => unawaited(_save()),
                    onClear: () => setState(() => _picks = const []),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.saving,
    required this.canClear,
    required this.onSave,
    required this.onClear,
  });

  final bool saving;
  final bool canClear;
  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: saving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentForeground,
                disabledBackgroundColor: AppColors.accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: saving
                  ? const AppProgressIndicator(
                      color: AppColors.accentForeground,
                      radius: 9,
                    )
                  : const Text('Save', style: AppTextStyles.buttonLabel),
            ),
          ),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: TextButton(
              onPressed: saving || !canClear ? null : onClear,
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: Text(
                'Clear all',
                style: AppTextStyles.buttonLabelSecondary.copyWith(
                  color: canClear
                      ? AppColors.accent
                      : AppColors.mutedForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
