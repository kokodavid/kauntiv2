import 'semantic_version.dart';

class AppUpdatePolicy {
  const AppUpdatePolicy({
    required this.currentVersion,
    required this.latestVersion,
    required this.requiredVersion,
    required this.storeUrl,
    required this.releaseNotes,
    required this.available,
    required this.required,
  });

  final SemanticVersion currentVersion;
  final SemanticVersion? latestVersion;
  final SemanticVersion? requiredVersion;
  final Uri? storeUrl;
  final String? releaseNotes;
  final bool available;
  final bool required;

  factory AppUpdatePolicy.fromJson(
    Map<String, dynamic> json,
    SemanticVersion current,
  ) {
    final latest = SemanticVersion.tryParse('${json['latest_version'] ?? ''}');
    final requiredVersion = SemanticVersion.tryParse(
      '${json['required_version'] ?? ''}',
    );
    final storeUrl = Uri.tryParse('${json['store_url'] ?? ''}');
    return AppUpdatePolicy(
      currentVersion: current,
      latestVersion: latest,
      requiredVersion: requiredVersion,
      storeUrl: storeUrl?.scheme == 'https' ? storeUrl : null,
      releaseNotes: json['release_notes'] as String?,
      available: json['available'] == true,
      required: json['required'] == true,
    );
  }
}
