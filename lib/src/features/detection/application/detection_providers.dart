import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../data/detection_repository.dart';
import '../data/local/detection_database.dart';
import '../domain/visit_rules.dart';

part 'detection_providers.g.dart';

/// Visit timings. Debug and profile builds use the short dev timings so
/// crossings can be tested on an emulator; `buildAppRoot` overrides this
/// from the flavor (dev flavor → dev timings, prod → production).
@Riverpod(keepAlive: true)
VisitTimings visitTimings(Ref ref) =>
    kReleaseMode ? VisitTimings.production : VisitTimings.dev;

/// The on-device detection database (`detection_queue`), open for the
/// life of the app.
@Riverpod(keepAlive: true)
DetectionDatabase detectionDatabase(Ref ref) {
  final db = DetectionDatabase();
  ref.onDispose(db.close);
  return db;
}

/// Detection state bound to the signed-in user (null when signed out, so
/// nothing is recorded or attributed without an owner).
@Riverpod(keepAlive: true)
DetectionRepository detectionRepository(Ref ref) => DetectionRepository(
  ref.watch(detectionDatabaseProvider),
  userId: ref.watch(supabaseClientProvider)?.auth.currentUser?.id,
  rules: VisitRules(ref.watch(visitTimingsProvider)),
);
