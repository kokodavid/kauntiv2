import 'dart:io';

import 'package:flutter/foundation.dart';

/// Whether the server's host can be reached right now (a DNS lookup: cheap,
/// and it fails fast with no connection). Web has no lookup, so it assumes
/// online. Tests swap this for a fake.
class ConnectivityProbe {
  const ConnectivityProbe(this.host);

  final String host;

  Future<bool> reachable() => reachableWithin(const Duration(seconds: 4));

  /// [reachable] with its own patience: a load that is starting wants a
  /// quick answer, not the background poll's.
  Future<bool> reachableWithin(Duration patience) async {
    if (kIsWeb) return true;
    try {
      final found = await InternetAddress.lookup(host).timeout(patience);
      return found.isNotEmpty && found.first.rawAddress.isNotEmpty;
    } on Object {
      return false;
    }
  }
}
