import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/services/location_diagnostics_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes a local report and summarizes battery samples', () async {
    final support = await Directory.systemTemp.createTemp('kaunti47-diag-');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async => support.path);
    addTearDown(() async {
      await LocationDiagnosticsStore.clear();
      await support.delete(recursive: true);
      messenger.setMockMethodCallHandler(channel, null);
    });

    await LocationDiagnosticsStore.clear();
    await LocationDiagnosticsStore.start(batteryPercent: 78);
    await LocationDiagnosticsStore.record('detection_cycle', {
      'gps_read': false,
      'crossing_reconciled': false,
    });
    await LocationDiagnosticsStore.stop(batteryPercent: 73);

    final report = await LocationDiagnosticsStore.latestReport();
    final rows = (await report!.readAsLines())
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final summary = await LocationDiagnosticsStore.summary();

    expect(rows.map((row) => row['event']), [
      'session_started',
      'detection_cycle',
      'session_stopped',
    ]);
    expect(rows.any((row) => row.containsKey('latitude')), isFalse);
    expect(rows.any((row) => row.containsKey('user_id')), isFalse);
    expect(summary, contains('Battery: 78% to 73%'));
  });
}
