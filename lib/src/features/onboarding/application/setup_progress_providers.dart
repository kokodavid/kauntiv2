import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/setup_progress_store.dart';

/// Whether new-user setup is under way on this phone. Tests override it.
final setupProgressStoreProvider = Provider<SetupProgressStore>(
  (ref) => const SharedPreferencesSetupProgressStore(),
);
