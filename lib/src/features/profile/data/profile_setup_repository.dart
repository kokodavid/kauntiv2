import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../counties/county_paths.dart';

abstract interface class ProfileSetupRepository {
  Future<CountyPath?> fetchHomeCounty();
  Future<void> saveHomeCounty(CountyPath? county);
}

class SupabaseProfileSetupRepository implements ProfileSetupRepository {
  const SupabaseProfileSetupRepository(this.client);

  final SupabaseClient client;

  String _owner() {
    final owner = client.auth.currentUser?.id;
    if (owner == null) {
      throw StateError('Profile setup requires a session');
    }
    return owner;
  }

  @override
  Future<CountyPath?> fetchHomeCounty() async {
    final owner = _owner();
    final row = await client
        .from('profiles')
        .select('home_county_id, home_county_slug')
        .eq('id', owner)
        .maybeSingle()
        .timeout(const Duration(seconds: 8));

    final slug = row?['home_county_slug'] as String?;
    if (slug != null && CountyPaths.bySlug.containsKey(slug)) {
      return CountyPaths.bySlug[slug];
    }

    final code = row?['home_county_id'] as int?;
    if (code == null) {
      return null;
    }

    for (final county in CountyPaths.all) {
      if (county.code == code) {
        return county;
      }
    }
    return null;
  }

  @override
  Future<void> saveHomeCounty(CountyPath? county) async {
    final owner = _owner();
    await client
        .from('profiles')
        .upsert({
          'id': owner,
          'home_county_id': county?.code,
          'home_county_slug': county?.slug,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .timeout(const Duration(seconds: 8));
  }
}
