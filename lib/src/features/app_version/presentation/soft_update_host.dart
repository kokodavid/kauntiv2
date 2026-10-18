import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../journeys/application/journey_recorder.dart';
import '../application/app_update_providers.dart';
import 'soft_update_sheet.dart';

/// Offers the soft update sheet once Home has settled. Never during a Trip,
/// at most once per launch, and not at all when the release has no store
/// link yet (the Settings row carries that case).
class SoftUpdateHost extends ConsumerStatefulWidget {
  const SoftUpdateHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SoftUpdateHost> createState() => _SoftUpdateHostState();
}

class _SoftUpdateHostState extends ConsumerState<SoftUpdateHost> {
  Timer? _timer;
  bool _offered = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    if (_offered) return;
    _timer = Timer(const Duration(milliseconds: 1500), _offer);
  }

  Future<void> _offer() async {
    if (!mounted || _offered) return;
    if (ref.read(journeyRecorderProvider) != null) return;
    final due = await ref
        .read(appUpdateControllerProvider.notifier)
        .softSheetDue();
    if (!mounted || !due || ref.read(journeyRecorderProvider) != null) return;
    _offered = true;
    await showSoftUpdateSheet(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    // The check can resolve after Home appears; try again when it does.
    ref.listen(appUpdateControllerProvider, (_, _) => _schedule());
    return widget.child;
  }
}
