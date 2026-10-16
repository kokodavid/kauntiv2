import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'explore_dock_collapse_provider.g.dart';

@Riverpod(keepAlive: true)
class ExploreDockCollapsed extends _$ExploreDockCollapsed {
  @override
  bool build() => false;

  void set(bool collapsed) {
    if (state != collapsed) state = collapsed;
  }
}
