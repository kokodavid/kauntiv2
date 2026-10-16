import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/explore_headline_rotation_store.dart';

part 'explore_headline_rotation_provider.g.dart';

/// Which liked type leads the Places sentence this app launch: a counter
/// kept on this phone that goes up by one per launch, so the sentence takes
/// the nearby types in turn. Kept alive, so it holds still for the whole
/// session. Local only; 0 when storage is unavailable.
@Riverpod(keepAlive: true)
Future<int> exploreHeadlineRotation(Ref ref) async {
  return ExploreHeadlineRotationStore().next();
}
