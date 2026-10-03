import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract final class LocationDiagnosticsStore {
  static Future<void> _writes = Future<void>.value();

  static Future<Directory> _directory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/location_diagnostics');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  static Future<File> _activeFile() async =>
      File('${(await _directory()).path}/active.json');

  static Future<void> start({required int batteryPercent}) async {
    final directory = await _directory();
    final id = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
    final log = File('${directory.path}/$id.jsonl');
    await log.create();
    await _append(log, 'session_started', {
      'battery_percent': batteryPercent,
    });
    await (await _activeFile()).writeAsString(
      jsonEncode({'id': id, 'path': log.path}),
    );
  }

  static Future<void> record(
    String event, [
    Map<String, Object?> data = const {},
  ]) async {
    final path = await _activePath();
    if (path == null) return;
    await _append(File(path), event, data);
  }

  static Future<void> stop({required int batteryPercent}) async {
    await record('session_stopped', {'battery_percent': batteryPercent});
    final active = await _activeFile();
    if (await active.exists()) await active.delete();
  }

  static Future<bool> isActive() async => await _activePath() != null;

  static Future<File?> latestReport() async {
    await _writes;
    final active = await _activePath();
    if (active != null) return File(active);
    final directory = await _directory();
    final logs = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.jsonl'))
        .cast<File>()
        .toList();
    if (logs.isEmpty) return null;
    logs.sort((a, b) => b.path.compareTo(a.path));
    return logs.first;
  }

  static Future<String?> summary() async {
    final report = await latestReport();
    if (report == null) return null;
    final lines = await report.readAsLines();
    final counts = <String, int>{};
    int? firstBattery;
    int? lastBattery;
    for (final line in lines.where((line) => line.isNotEmpty)) {
      final row = jsonDecode(line) as Map<String, dynamic>;
      final event = row['event'] as String;
      counts.update(event, (count) => count + 1, ifAbsent: () => 1);
      final data = row['data'];
      if (data is Map && data['battery_percent'] is int) {
        final battery = data['battery_percent'] as int;
        if (battery < 0) continue;
        firstBattery ??= battery;
        lastBattery = battery;
      }
    }
    final eventSummary = counts.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
    return [
      'Kaunti47 location diagnostics',
      'Session: ${report.uri.pathSegments.last}',
      'Events: $eventSummary',
      if (firstBattery != null && lastBattery != null)
        'Battery: $firstBattery% to $lastBattery%',
      'Coordinates and account identifiers are not collected.',
    ].join('\n');
  }

  static Future<void> clear() async {
    await _writes;
    final directory = await _directory();
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  static Future<String?> _activePath() async {
    final file = await _activeFile();
    if (!await file.exists()) return null;
    final row = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return row['path'] as String?;
  }

  static Future<void> _append(
    File file,
    String event,
    Map<String, Object?> data,
  ) {
    final write = _writes.then((_) async {
      await file.writeAsString(
        '${jsonEncode({
          'at': DateTime.now().toUtc().toIso8601String(),
          'event': event,
          'data': data,
        })}\n',
        mode: FileMode.append,
        flush: false,
      );
    });
    _writes = write.catchError((Object _) {});
    return write;
  }
}
