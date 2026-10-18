import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottom_nav_hidden_provider.g.dart';

/// Whether the active tab wants the floating tab bar tucked away (Explore
/// does while the traveller scrolls down or types). The shell only honours
/// it on the tab that set it, so it can never leave the bar hidden elsewhere.
@Riverpod(keepAlive: true)
class BottomNavHidden extends _$BottomNavHidden {
  @override
  bool build() => false;

  void set({required bool hidden}) {
    if (state != hidden) state = hidden;
  }
}
