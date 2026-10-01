import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/journey_entitlement.dart';
import '../application/journey_recorder.dart';
import '../domain/pro_status.dart';
import 'journey_messages.dart';

/// Opens the OS settings (location permission); supplied by `app/`.
typedef OpenAppSettings = Future<void> Function();

/// "Record a Trip" and the Start button, compact enough to sit above the
/// history list without dominating the page: an icon, title and a short
/// status line on the left, a usage pill (PRO, or "x/3 this month" for a
/// free account) and the Start button on the right. Every reason Start
/// can fail is explained: the free Trip allowance is used up for this
/// month, offline (entitlement needs a live check) or location the phone
/// won't give.
class JourneyStartCard extends ConsumerStatefulWidget {
  const JourneyStartCard({super.key, this.onOpenSettings, this.onStarted});

  final OpenAppSettings? onOpenSettings;

  /// Runs once recording starts (opens the full-screen map).
  final void Function(BuildContext context)? onStarted;

  @override
  ConsumerState<JourneyStartCard> createState() => _JourneyStartCardState();
}

class _JourneyStartCardState extends ConsumerState<JourneyStartCard> {
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    // Best-effort: shows an accurate usage pill before Start is even
    // tapped. canStart() at the actual Start time is still authoritative.
    unawaited(ref.read(journeyEntitlementProvider.notifier).refreshAccess());
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await ref.read(journeyRecorderProvider.notifier).start();
      if (mounted) widget.onStarted?.call(context);
    } on Object catch (error) {
      if (!mounted) return;
      if (error is JourneyTrialExhausted) {
        await _showTrialExhausted();
      } else {
        _showError(error);
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _showTrialExhausted() {
    final trial = ref.read(journeyTrialUsageProvider);
    final body = trial == null
        ? JourneyMessages.trialExhaustedBody
        : "You've recorded ${trial.tripLimit} Trips this month, the limit "
              'on the free plan. Upgrade to Pro for unlimited Trips, or try '
              'again after it resets on ${_resetDay(trial.resetsAt)}.';
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(JourneyMessages.trialExhaustedTitle),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static String _resetDay(DateTime resetsAt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = resetsAt.toLocal();
    return '${local.day} ${months[local.month - 1]}';
  }

  void _showError(Object error) {
    final message = JourneyMessages.forError(error);
    if (message == null) return;
    final settings = widget.onOpenSettings;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: settings != null && JourneyMessages.opensSettings(error)
              ? SnackBarAction(label: 'Settings', onPressed: settings)
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final pro = ref.watch(journeyEntitlementProvider);
    final trial = ref.watch(journeyTrialUsageProvider);
    final isPro = pro?.allowsStartAt(DateTime.now()) ?? false;
    final exhausted = !isPro && trial != null && !trial.hasRemaining;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0x1F0A84FF), // accent at 12% opacity
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Record a Trip',
                        style: AppTypeScale.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isPro)
                      const _ProChip()
                    else if (trial != null)
                      _TrialPill(trial: trial),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isPro
                      ? 'Recorded privately, even with your phone locked.'
                      : trial == null
                      ? 'Even with your phone locked.'
                      : exhausted
                      ? 'Resets ${_resetDay(trial.resetsAt)}.'
                      : '${trial.tripsRemaining} of ${trial.tripLimit} free '
                            'Trips left this month.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _starting
                  ? null
                  : exhausted
                  ? _showTrialExhausted
                  : _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentForeground,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _starting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentForeground,
                      ),
                    )
                  : Text(
                      exhausted ? 'Details' : 'Start Trip',
                      style: AppTextStyles.buttonLabel,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProChip extends StatelessWidget {
  const _ProChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.explorePromotionFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'PRO',
        style: AppTypeScale.meta.copyWith(
          color: AppColors.explorePromotionText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// This month's free-Trip usage ("2/3"), neutral while Trips remain and
/// switching to the same warm tone as [_ProChip] once they're used up, so
/// the one moment that actually needs attention is the one that stands
/// out.
class _TrialPill extends StatelessWidget {
  const _TrialPill({required this.trial});

  final JourneyTrialStatus trial;

  @override
  Widget build(BuildContext context) {
    final exhausted = !trial.hasRemaining;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: exhausted
            ? AppColors.explorePromotionFill
            : AppColors.lockedFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${trial.tripsUsed}/${trial.tripLimit}',
        style: AppTypeScale.meta.copyWith(
          color: exhausted
              ? AppColors.explorePromotionText
              : AppColors.mutedForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
