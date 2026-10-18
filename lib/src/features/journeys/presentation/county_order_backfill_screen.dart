import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/county_order_backfill.dart';
import '../application/journey_cloud_providers.dart';

/// Dev builds only: saves the county order for this account's existing
/// trips (new uploads save it themselves).
class CountyOrderBackfillScreen extends ConsumerStatefulWidget {
  const CountyOrderBackfillScreen({super.key});

  @override
  ConsumerState<CountyOrderBackfillScreen> createState() =>
      _CountyOrderBackfillScreenState();
}

class _CountyOrderBackfillScreenState
    extends ConsumerState<CountyOrderBackfillScreen> {
  bool _running = false;
  String _status = 'Not run yet.';

  Future<void> _run() async {
    final repo = ref.read(supabaseJourneyRepositoryProvider);
    if (repo == null) {
      setState(() => _status = 'Not signed in.');
      return;
    }
    setState(() {
      _running = true;
      _status = 'Reading trips...';
    });
    try {
      final result = await backfillCountyOrder(
        repo,
        onProgress: (done, total) {
          if (mounted) setState(() => _status = 'Trip $done of $total...');
        },
      );
      if (mounted) {
        setState(
          () => _status =
              'Done. ${result.updated} trips updated, ${result.failed} failed.',
        );
      }
    } on Object catch (error) {
      if (mounted) setState(() => _status = 'Stopped: $error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('County order')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saves the order each of your trips crossed its counties, '
              'worked out from the saved route.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _running ? null : () => unawaited(_run()),
              child: Text(_running ? 'Running...' : 'Backfill my trips'),
            ),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
