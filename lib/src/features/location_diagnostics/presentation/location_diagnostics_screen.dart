import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/app_share.dart';
import '../../../core/services/location_diagnostics.dart';

class LocationDiagnosticsScreen extends StatefulWidget {
  const LocationDiagnosticsScreen({super.key});

  @override
  State<LocationDiagnosticsScreen> createState() =>
      _LocationDiagnosticsScreenState();
}

class _LocationDiagnosticsScreenState extends State<LocationDiagnosticsScreen> {
  late Future<bool> _active;
  late Future<String?> _summary;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _active = LocationDiagnostics.isActive();
    _summary = LocationDiagnostics.summary();
  }

  Future<void> _toggle(BuildContext context, bool active) async {
    try {
      if (active) {
        await LocationDiagnostics.stop();
      } else {
        await LocationDiagnostics.start();
      }
      if (context.mounted) setState(_reload);
    } on Object {
      if (context.mounted) _message(context, "Couldn't update the session.");
    }
  }

  Future<void> _share(BuildContext context) async {
    try {
      final path = await LocationDiagnostics.reportPath();
      if (path == null) {
        _message(context, 'Record a session first.');
        return;
      }
      await AppShare.file(path, text: await LocationDiagnostics.summary());
    } on Object {
      if (context.mounted) _message(context, "Couldn't share the report.");
    }
  }

  Future<void> _copy(BuildContext context) async {
    final summary = await LocationDiagnostics.summary();
    if (summary == null) {
      _message(context, 'Record a session first.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: summary));
    if (context.mounted) _message(context, 'Summary copied.');
  }

  Future<void> _clear(BuildContext context) async {
    await LocationDiagnostics.clear();
    if (context.mounted) setState(_reload);
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<bool>(
      future: _active,
      builder: (context, activeSnapshot) {
        if (!activeSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final active = activeSnapshot.data!;
        return FutureBuilder<String?>(
          future: _summary,
          builder: (context, summarySnapshot) {
            final summary = summarySnapshot.data;
            return Scaffold(
              appBar: AppBar(title: const Text('Location diagnostics')),
              body: summarySnapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            active
                                ? Icons.fiber_manual_record
                                : Icons.circle_outlined,
                            color: active
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                          title: Text(
                            active ? 'Recording diagnostics' : 'Stopped',
                          ),
                          subtitle: const Text('Stored on this device only'),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => unawaited(_toggle(context, active)),
                          icon: Icon(active ? Icons.stop : Icons.play_arrow),
                          label: Text(active ? 'Stop session' : 'Start session'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: summary == null
                                    ? null
                                    : () => unawaited(_share(context)),
                                icon: const Icon(Icons.ios_share),
                                label: const Text('Share report'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: summary == null
                                    ? null
                                    : () => unawaited(_copy(context)),
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy summary'),
                              ),
                            ),
                          ],
                        ),
                        if (summary != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Latest session',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(summary),
                          const SizedBox(height: 8),
                          Text(
                            'Battery change is approximate; pair this report '
                            'with the platform profiler.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: active
                                  ? null
                                  : () => unawaited(_clear(context)),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Clear local reports'),
                            ),
                          ),
                        ],
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
