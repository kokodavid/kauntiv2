import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_version_provider.g.dart';

/// The installed app's version and build, like "1.0.3 (42)". Null when the
/// platform cannot say, so a screen simply shows nothing.
@Riverpod(keepAlive: true)
Future<String?> appVersion(Ref ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber.isEmpty
        ? info.version
        : '${info.version} (${info.buildNumber})';
  } on Object {
    return null;
  }
}
