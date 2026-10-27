import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/push_providers.dart';
import '../domain/push_destination.dart';
import '../domain/push_sync_report.dart';

/// Dev builds only: why this phone's push token is or is not on the server.
/// Release builds log nothing, so this is how a tester on TestFlight can
/// read the cause straight off the phone.
class PushStatusScreen extends ConsumerStatefulWidget {
  const PushStatusScreen({super.key});

  @override
  ConsumerState<PushStatusScreen> createState() => _PushStatusScreenState();
}

class _PushStatusScreenState extends ConsumerState<PushStatusScreen> {
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    await ref.read(pushRegistrarProvider).sync();
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final registrar = ref.watch(pushRegistrarProvider);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Push status')),
      body: StreamBuilder<PushSyncReport?>(
        stream: registrar.reports,
        initialData: registrar.report,
        builder: (context, snapshot) => _body(registrar.flavor, snapshot.data),
      ),
    );
  }

  Widget _body(String flavor, PushSyncReport? report) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _Row('Result', _result(report), strong: true),
      if (report != null) ..._rows(report),
      _Row('Flavor', flavor),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _syncing ? null : () => unawaited(_sync()),
        child: Text(_syncing ? 'Syncing…' : 'Sync now'),
      ),
    ],
  );

  List<Widget> _rows(PushSyncReport report) => [
    _Row('Last attempt', report.at.toLocal().toString().split('.').first),
    _Row('Permission', report.permission?.name ?? 'not read'),
    _Row('Push token', PushSyncReport.tail(report.token)),
    _Row('Apple (APNs) token', PushSyncReport.tail(report.apnsToken)),
    if (report.detail != null) _Row('Detail', report.detail!),
  ];

  String _result(PushSyncReport? report) => switch (report?.step) {
    null => 'No attempt yet (tap Sync now)',
    PushSyncStep.firebase => 'Stopped: Firebase unavailable',
    PushSyncStep.token => 'Stopped: no push token from the phone',
    PushSyncStep.register => 'Stopped: the server call failed',
    PushSyncStep.registered =>
      report?.permission == PushPermission.granted
          ? 'Registered with the server'
          : 'Registered, but notifications are not allowed',
  };
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: TextStyle(
            fontSize: strong ? 16 : 14,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.foreground,
          ),
        ),
      ],
    ),
  );
}
