import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/setup_progress_store.dart';

part 'setup_progress_providers.g.dart';

/// Whether new-user setup is under way on this phone. Tests override it.
@Riverpod(keepAlive: true)
SetupProgressStore setupProgressStore(Ref ref) =>
    const SharedPreferencesSetupProgressStore();
