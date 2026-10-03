import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/journey_entitlement.dart';
import '../application/journey_recorder.dart';
import '../domain/pro_status.dart';
import 'journey_messages.dart';
import 'journey_transport_mode_ui.dart';

/// Opens the OS settings (location permission); supplied by `app/`.
typedef OpenAppSettings = Future<void> Function();

/// "Record a Trip" and the Start button, as a solid accent-coloured
/// widget: a title and a short status line in white on the left, and a
/// white Start button (a small red "record" dot + the label) on the
/// right. Every reason Start can fail is explained: the free Trip
/// allowance is used up for this month, offline (entitlement needs a
/// live check) or location the phone won't give.
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
    // Best-effort: shows an accurate status line before Start is even
    // tapped. canStart() at the actual Start time is still authoritative.
    unawaited(ref.read(journeyEntitlementProvider.notifier).refreshAccess());
  }

  Future<void> _start() async {
    // Mandatory every time: dismissing without choosing leaves Start
    // untouched rather than falling back to some assumed mode.
    final mode = await JourneyTransportModePicker.choose(context);
    if (mode == null || !mounted) return;
    setState(() => _starting = true);
    try {
      await ref.read(journeyRecorderProvider.notifier).start(mode: mode);
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
    final hasSettingsAction =
        settings != null && JourneyMessages.opensSettings(error);
    showAppToast(
      context,
      variant: AppToastVariant.error,
      title: "Couldn't start the Trip",
      message: message,
      actionLabel: hasSettingsAction ? 'Settings' : null,
      onAction: hasSettingsAction ? settings : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pro = ref.watch(journeyEntitlementProvider);
    final trial = ref.watch(journeyTrialUsageProvider);
    final isPro = pro?.allowsStartAt(DateTime.now()) ?? false;
    final exhausted = !isPro && trial != null && !trial.hasRemaining;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record a Trip',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.sectionTitle.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // A prompt to act, not a feature description - what
                  // "Recorded privately, even with your phone locked."
                  // used to be. The trial-aware lines stay informational
                  // since they're explaining a constraint, not selling
                  // the feature.
                  isPro || trial == null
                      ? 'Tap Start to begin recording'
                      : exhausted
                      ? 'Free limit reached · resets '
                            '${_resetDay(trial.resetsAt)}'
                      : '${trial.tripsRemaining} of ${trial.tripLimit} free '
                            'Trips left this month',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeScale.meta.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
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
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: const StadiumBorder(),
              ),
              child: _starting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!exhausted) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          exhausted ? 'Details' : 'Start',
                          style: AppTextStyles.buttonLabel.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
