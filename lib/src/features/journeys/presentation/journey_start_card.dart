import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../application/journey_recorder.dart';
import '../domain/pro_status.dart';
import 'journey_messages.dart';

/// Opens the OS settings (location permission); supplied by `app/`.
typedef OpenAppSettings = Future<void> Function();

/// "Record a Journey" and the Start button, with every reason Start can
/// fail explained: no Pro, offline (Pro needs a live check) or location
/// the phone won't give.
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

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await ref.read(journeyRecorderProvider.notifier).start();
      if (mounted) widget.onStarted?.call(context);
    } on Object catch (error) {
      if (!mounted) return;
      if (error is JourneyStartDenied) {
        await _showProRequired();
      } else {
        _showError(error);
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _showProRequired() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(JourneyMessages.proRequiredTitle),
      content: const Text(JourneyMessages.proRequiredBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route_rounded, color: AppColors.accent),
              SizedBox(width: 8),
              Expanded(
                child: Text('Record a Trip', style: AppTypeScale.cardTitle),
              ),
              _ProChip(),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Your route is drawn as you travel, even with the phone locked, '
            'and saved privately to your account. Pause or stop any time.',
            style: AppTypeScale.body,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _starting ? null : _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentForeground,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
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
                  : const Text('Start Trip', style: AppTextStyles.buttonLabel),
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
