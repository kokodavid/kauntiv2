import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_screen.g.dart';

/// The path of the screen the user was last on, kept by the router so a
/// bug report can say where it happened. Pages that are not part of normal
/// browsing (the feedback form itself) are not recorded.
@Riverpod(keepAlive: true)
class LastScreen extends _$LastScreen {
  @override
  String? build() => null;

  void record(String path) {
    if (path.startsWith('/feedback')) return;
    if (state != path) state = path;
  }
}
