import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/public_trip_providers.dart';
import '../domain/public_trip_moment_kind.dart';
import '../domain/public_trip_share_preferences.dart';

/// What starts switched on when you make a trip public. Changing these
/// never changes a trip that is already public.
class PublicTripDefaultsScreen extends ConsumerWidget {
  const PublicTripDefaultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicTripSharePreferencesControllerProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: AppBackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        title: const Text('Share defaults', style: AppTextStyles.detailNavTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text(
              "Couldn't load your defaults.",
              style: AppTextStyles.bodyMuted,
            ),
          ),
          data: (prefs) => _Body(prefs: prefs),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.prefs});

  final PublicTripSharePreferences prefs;

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    PublicTripSharePreferences next,
  ) async {
    try {
      await ref
          .read(publicTripSharePreferencesControllerProvider.notifier)
          .save(next);
    } on Object {
      if (!context.mounted) return;
      showAppToast(
        context,
        variant: AppToastVariant.error,
        title: "Couldn't save your defaults",
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        const Text(
          'These are switched on to start with when you make a trip public. You can still change them for each trip.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 12),
        for (final kind in PublicTripMomentKind.values)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: AppColors.accent,
            value: prefs.includes(kind),
            onChanged: (value) =>
                unawaited(_save(context, ref, prefs.withKind(kind, value))),
            title: Text(kind.label, style: AppTextStyles.listItemTitle),
            subtitle: kind.hint == null
                ? null
                : Text(kind.hint!, style: AppTextStyles.listItemSubtitle),
          ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          activeTrackColor: AppColors.accent,
          value: prefs.photos,
          onChanged: (value) =>
              unawaited(_save(context, ref, prefs.copyWith(photos: value))),
          title: const Text('Photos', style: AppTextStyles.listItemTitle),
          subtitle: const Text(
            'Pre-select photos from the trip.',
            style: AppTextStyles.listItemSubtitle,
          ),
        ),
        const SizedBox(height: 18),
        const Text('Hidden at each end', style: AppTextStyles.listItemTitle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final meters in PublicTripSharePreferences.trimChoices)
              ChoiceChip(
                label: Text(meters >= 1000 ? '${meters ~/ 1000} km' : '$meters m'),
                selected: prefs.trimMeters == meters,
                onSelected: (_) => unawaited(
                  _save(context, ref, prefs.copyWith(trimMeters: meters)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
